# Copyright (c) 2016, 2020, Cody Opel <cwopel@chlorm.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# FIXME: Make sure user-agent handling is fully ported.
# https://github.com/chlorm/kratos/tree/c82657c9565ce041ade093c473c3f6d0b25be0ad/plugins/user-agent


# Automatically sets SSH_AUTH_SOCK to the correct agent and starts the agent
# if it isn't running.


use str
use github.com/chlorm/elvish-stl/io
use github.com/chlorm/elvish-stl/os
use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/utils
use github.com/chlorm/elvish-util-wrappers/gnome-keyring-daemon
use github.com/chlorm/elvish-util-wrappers/gpg-agent
use github.com/chlorm/elvish-util-wrappers/ssh-agent
use github.com/chlorm/elvish-xdg/xdg


var CACHE_DIR = (xdg:get-dir 'XDG_RUNTIME_DIR')'/agent-auto'
var CACHE_SOCKET = $CACHE_DIR'/socket'
var CACHE_PID = $CACHE_DIR'/pid'

var s-gnome-keyring = 'gnome-keyring-daemon'
var s-gpg-agent = 'gpg-agent'
var s-ssh-agent = 'ssh-agent'

fn get-cmd {
    var agent-cmds = [
        $s-ssh-agent
        $s-gnome-keyring
        $s-gpg-agent
    ]

    put (utils:get-preferred-cmd 'PREFERRED_SSH_AGENTS' $agent-cmds)
}

fn get-socket [agent]{
    if (==s $s-gnome-keyring $agent) {
        put $gnome-keyring:SOCKET_SSH
    } elif (==s $s-gpg-agent $agent) {
        put $gpg-agent:SOCKET_SSH
    } elif (==s $s-ssh-agent $agent) {
        put $ssh-agent:SOCKET
    }
    fail
}

fn cache-write [agent]{
    os:makedir $CACHE_DIR
    os:chmod 0700 $CACHE_DIR
    print (get-socket $agent) >$CACHE_SOCKET
    print (pidof $agent) >$CACHE_PID
}

fn cache-read {
    if (not (os:exists $CACHE_DIR)) {
        fail
    }
    set-env 'SSH_AUTH_SOCK' (io:cat $CACHE_SOCKET)
    set-env 'SSH_AGENT_PID' (io:cat $CACHE_PID)
}

# NOTE: This is only meant as a fallback if the agent isn't running. It is
#       recommended to start the needed agents with your service manager.
fn start-manually [agent] {
    if (==s $s-gnome-keyring $agent) {
        $gnome-keyring:start
    } elif (==s $s-gpg-agent $agent) {
        $gpg-agent:start
    } elif (==s $s-ssh-agent $agent) {
        $ssh-agent:start
    }
    fail
}

var proper-iter = 1
fn check-proper [agent]{
    var running = $false
    for local:i [ (e:ps x) ] {
        if (re:match $agent $i) {
            set running = $true
            break
        }
    }

    if $running {
        # If the agent is running on a socket that isn't the expected one we
        # must kill the daemon and restart it manually.
        if (not (os:is-socket (get-socket $agent))) {
            e:kill (e:pidof $agent)
            unset-env 'SSH_AGENT_PID'
            unset-env 'SSH_AUTH_SOCK'
            start-manually $agent
        }
    } else {
        start-manually $agent
    }

    # Recursively check
    if (> $proper-iter 3) {
        return
    }
    check-proper $agent
    set proper-iter = (+ $proper-iter 1)
}

fn init-instance {
    var tty = (e:tty)
    set-env 'GPG_TTY' $tty
    set-env 'SSH_TTY' $tty
    cache-read

    # FIXME: document HACK
    if ?(has-env 'SSH_ASKPASS' >$os:NULL) {
        unset-env 'SSH_ASKPASS'
    }
}

fn init-session {
    var agent = (get-cmd)

    check-proper $agent
    set-permissions $agent
    cache-write $agent
}
