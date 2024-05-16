#!/bin/bash
# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail

if [ -z "${GITHUB_WORKSPACE}" ]; then
    echo 'Probably you are running this Docker image not from GitHub Actions.'
    echo 'In order to do it right, do this:'
    echo '  docker build . -t judges-action'
    echo '  docker run -it --rm --entrypoint /bin/bash judges-action'
    exit 1
fi

export GLI_DEBUG=true

cd "${GITHUB_WORKSPACE-/w}"

fb=${INPUT_FACTBASE}

set -x

declare -a options=()
while IFS= read -r o; do
    v=$(echo "${o}" | xargs)
    if [ "${v}" = "" ]; then continue; fi
    options+=("--option=${v}")
done <<< "${INPUT_OPTIONS}"

if [ -e "${fb}" ]; then
    # Remove facts that are too old
    judges --verbose trim "${fb}"
fi

# Add new facts, using the judges (Ruby scripts) in the /judges directory
judges --verbose update --quiet --max-cycles 5 "${options[@]}" /judges-action/judges "${fb}"

# Convert the factbase to a few human-readable formats
if [ -z "${INPUT_PAGES}" ]; then
    echo "It is mandatory to specify 'pages' argument, which is the name"
    echo "of a directory where YAML, JSON, and other human-readable files are generated"
    exit 1
fi
mkdir -p "${INPUT_PAGES}"
for f in yaml xml json; do
    judges print --format "${f}" --auto "${fb}"
    mv "${fb%.*}.${f}" "${INPUT_PAGES}"
done
