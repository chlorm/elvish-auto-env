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


use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/utils


fn get {
    var pagers = [
        'less'
        'most'
        'more'
    ]

    var pager = (utils:get-preferred-cmd 'PREFERRED_PAGERS' $pagers)

    put $pager
}

fn set {|&static=$nil|
    var pager = $static
    if (eq $static $nil) {
        set pager = (get)
    }
    set-env 'PAGER' $pager
    set-env 'MANPAGER' $pager

    if (==s (path:basename $pager) 'less') {
        set-env 'LESS' '--RAW-CONTROL-CHARS'
        set-env 'LESSCHARSET' 'utf-8'
        unset-env 'LESS_IS_MORE'
        set-env 'LESS_TERMCAP_mb' (e:tput 'blink'; e:tput 'setaf' 3)
        set-env 'LESS_TERMCAP_md' (e:tput 'bold'; e:tput 'setaf' 6)
        set-env 'LESS_TERMCAP_me' (e:tput 'sgr0')
        set-env 'LESS_TERMCAP_so' (e:tput 'smso'; e:tput 'setaf' 8; e:tput 'setab' 3)
        set-env 'LESS_TERMCAP_se' (e:tput 'sgr0'; e:tput 'rmso')
        set-env 'LESS_TERMCAP_us' (e:tput 'smul'; e:tput 'setaf' 3)
        set-env 'LESS_TERMCAP_ue' (e:tput 'sgr0'; e:tput 'rmul')
        set-env 'LESS_TERMCAP_mr' (e:tput 'rev')
        set-env 'LESS_TERMCAP_mh' (e:tput 'dim')

        # some terminals don't understand SGR escape sequences
        set-env 'GROFF_NO_SGR' 1
    }
}
