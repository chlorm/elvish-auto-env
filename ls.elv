# Copyright (c) 2020, Cody Opel <cwopel@chlorm.net>
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


use github.com/chlorm/elvish-stl/regex


fn get {
    put (regex:find "'(.*)'" [ (e:dircolors '-b') ][0])
}

fn set [&static=$nil]{
    var d = $nil
    if (not (eq $static $nil)) {
        set d = $static
    } else {
        # Don't fail on systems without `dircolors`.
        try {
            set d = (get)
        } except e { echo $e['reason'] >&2 }
    }
    if (not (eq $d $nil)) {
        set-env 'LS_COLORS' $d
    }
    # BSD
    set-env 'CLICOLOR' 1
    set-env 'LSCOLORS' 'ExGxFxdxCxDhDxaBadaCeC'
}
