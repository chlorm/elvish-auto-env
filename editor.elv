# Copyright (c) 2015, 2020, Cody Opel <cwopel@chlorm.net>
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


use platform
use str
use github.com/chlorm/elvish-stl/list
use github.com/chlorm/elvish-stl/os


# TODO: simplify to only true statements
var EDITORS = [
    &atom=[
        &term=$false
        &gui=$true
        &gui-args=[
            '--new-window'
            '--wait'
        ]
        &cmds=[
            'atom-nightly'
            'atom-beta'
        ]
    ]
    &emacs=[
        &term=$true
        &term-args=[
            '--no-window-system'
        ]
        &gui=$true
    ]
    &gedit=[
        &term=$false
        &gui=$true
    ]
    &gvim=[
        &term=$false
        &gui=$true
    ]
    &kate=[
        &term=$false
        &gui=$true
    ]
    &mg=[
        &term=$true
        &gui=$false
    ]
    &micro=[
        &term=$true
        &gui=$false
    ]
    &nano=[
        &term=$true
        &gui=$false
    ]
    &nvim=[
        &term=$true
        &gui=$false  # FIXME
    ]
    &sublime=[
        &term=$false
        &gui=$true
        &gui-args=[
            '--new-window'
            '--wait'
        ]
        &cmds=[
            'subl'
        ]
    ]
    &vi=[
        &term=$true
        &gui=$false
    ]
    &vim=[
        &term=$true
        &gui=$false
    ]
    &vscode=[
        &term=$false
        &gui=$true
        &cmds=[
            'code-insiders'
            'code'
        ]
        &gui-args=[
            '--new-window'
            '--wait'
        ]
    ]
    &yi=[
        &term=$true
        &gui=$false
    ]
]

# Create a map of editor name to alternate commands
fn -alt-cmd-map {
    var editorMap = [&]
    for i [ (keys $EDITORS) ] {
        if (has-key $EDITORS[$i] 'cmds') {
            for cmd $EDITORS[$i]['cmds'] {
                set editorMap[$cmd] = $i
            }
        }
    }
    put $editorMap
}

# Returns the first preferred editor found.
# PREFERRED_EDITORS is a comma separated list of editors as listed in the
# keys of the `editors` map above.
# EXCLUDED_EDITORS is a comma separated list of editor commands.
fn get {
    var hasDisplay = $false
    if $platform:is-windows {
        # Assume Windows is only headless over SSH
        set hasDisplay = (not (bool ?(get-env 'SSH_CLIENT' >$os:NULL)))
    } else {
        set hasDisplay = (bool ?(get-env 'DISPLAY' >$os:NULL))
    }

    var default = [
        'vscode'
        'vim'
        'vi'
    ]

    var preferred = $default
    try {
        set preferred = [ (str:split ',' (get-env 'PREFERRED_EDITORS')) ]
        if (==s $@preferred '') {
            fail
        }
    } except _ { }

    var cmds = [ ]
    var cmdArgs = [&]
    for i $preferred {
        if $hasDisplay {
            if (not $EDITORS[$i]['gui']) {
                continue
            }
            try {
                set cmdArgs[$i] = $EDITORS[$i]['gui-args']
            } except { }
        } else {
            if (not $EDITORS[$i]['term']) {
                continue
            }
            try {
                set cmdArgs[$i] = $EDITORS[$i]['term-args']
            } except { }
        }

        # Lookup alternate commands if any
        try {
            var tmp = $EDITORS[$i]['cmds']
            set cmds = [ $@cmds $@tmp ]
        } except _ { }

        # Add self
        set cmds = [ $@cmds $i ]
    }

    var excluded = [ ]
    try {
        set excluded = [ (str:split ',' (get-env 'EXCLUDED_EDITORS')) ]
    } except _ { }
    for exclude $excluded {
        set cmds = (list:drop $cmds $exclude)
    }

    var commandMap = (-alt-cmd-map)

    var path = $nil
    for i $cmds {
        try {
            set path = (search-external $i)
        } except _ {
            continue
        }
        try {
            if (has-key $commandMap $i) {
                set i = $commandMap[$i]
            }
            # FIXME: no way to override args
            #        Maybe EDITOR_<editor>_ARGS env var?
            set path = $path' '(str:join ' ' $cmdArgs[$i])
        } except _ { }
        break
    }

    if (eq $path $nil) {
        fail 'No command found in '(to-string $cmds)', install one or set PREFERRED_EDITORS'
    }

    put $path
}

fn set [&static=$nil]{
    var editor = $static
    if (eq $editor $nil) {
        set editor = (get)
    }
    set-env 'EDITOR' $editor
    set-env 'VISUAL' $editor
}
