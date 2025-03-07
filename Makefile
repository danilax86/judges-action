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

.SHELLFLAGS: -c
.ONESHELL:
.PHONY: clean test all entry entry rmi verify rubocop

all: rubocop test entry rmi verify

test: target/docker-image.txt
	img=$$(cat target/docker-image.txt)
	docker run --rm --entrypoint '/bin/bash' "$${img}" -c 'judges test --disable live --lib /judges-action/lib /judges-action/judges'
	echo "$$?" > target/test.exit

entry: target/docker-image.txt
	img=$$(cat target/docker-image.txt)
	(
		echo 'testing=yes'
		echo 'repositories=yegor256/judges'
		echo 'max_events=3'
	) > target/opts.txt
	docker run --rm \
		-e GITHUB_WORKSPACE=/tmp \
		-e INPUT_FACTBASE=/tmp/recent.fb \
		-e INPUT_PAGES=pages \
		-e "INPUT_OPTIONS=$$(cat target/opts.txt)" \
		"$${img}"
	echo "$$?" > target/entry.exit

rmi: target/docker-image.txt
	img=$$(cat $<)
	docker rmi "$${img}"
	rm "$<"

verify:
	e1=$$(cat target/test.exit)
	test "$${e1}" = "0"
	e2=$$(cat target/entry.exit)
	test "$${e2}" = "0"

target/docker-image.txt:
	mkdir -p "$$(dirname $@)"
	docker build -t judges-action -q . > "$@"

clean:
	rm -f target
