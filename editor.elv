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


use str
use github.com/chlorm/elvish-stl/list


# TODO: simplify to only true statements
local:editors = [
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
    ]
    &yi=[
        &term=$true
        &gui=$false
    ]
]

# Returns the first preferred editor found.
# PREFERRED_EDITORS is a comma separated list of editors as listed in the
# keys of the `editors` map above.
# EXCLUDED_EDITORS is a comma separated list of editor commands.
fn get {
    local:has-display = (bool ?(get-env DISPLAY >/dev/null))

    local:defaults = [
        'vscode'
        'vim'
        'vi'
    ]

    local:preferred = $defaults
    try {
        preferred = [ (str:split ',' (get-env PREFERRED_EDITORS)) ]
    } except _ { }

    local:cmds = [ ]
    local:args = [&]
    for local:i $defaults {
        if $has-display {
            if (not $editors[$i][gui]) {
                continue
            }
            try {
                args[$i] = $editors[$i][gui-args]
            } except { }
        } else {
            if (not $editors[$i][term]) {
                continue
            }
            try {
                args[$i] = $editors[$i][term-args]
            } except { }
        }

        # Lookup alternate commands if any
        local:tmp = [ ]
        try {
            tmp = $editors[$i][cmds]
            cmds = [ $@cmds $@tmp ]
        } except _ { }

        # Add self
        cmds = [ $@cmds $i ]
    }

    local:excluded = [ ]
    try {
        excluded = [ (str:split ',' (get-env EXCLUDED_EDITORS)) ]
    } except _ { }
    for local:x $excluded {
        cmds = (list:drop $cmds $x)
    }

    local:path = ''
    for local:i $cmds {
        try {
            path = (search-external $i)
        } except _ {
            continue
        }
        try {
            # FIXME: no way to override args
            #        Maybe EDITOR_<editor>_ARGS env var?
            path = $path' '(str:join ' ' $args[$i])
        } except _ { }
        break
    }

    if (==s $path '') {
        fail 'No command found in '(to-string $cmds)', install one or set PREFERRED_EDITORS'
    }

    put $path
}

fn set [&static=$nil]{
    local:editor = $nil
    if (not (eq $static $nil)) {
        editor = $static
    } else {
        editor = (get)
    }
    set-env EDITOR $editor
    set-env VISUAL $editor
}
