**HEADS-UP** [2020-06-11]: This fork is about to reboot at https://github.com/modernish/ast, as a fork based off the official AT&T AST repo. There is nothing wrong at all with how ksh-community bootstrapped the fork this one is based on, but there are too many associated interpersonal conflicts between them and the former ksh2020 camp; rebasing off the archived AT&T repo allows for neutrality, which allows concentrating on actually fixing ksh. It will also restore `nmake` and `pty` which allow the regression tests for the interactive shell to work. All changes made here will be reapplied at the new fork; nothing will be lost. In the meantime, this fork is archived. I apologise for the temporary upheaval. Please bear with me while I execute the transition.

# KornShell 93u+m

This repository is used to maintain bugfixes
to the last stable release (93u+ 2012-08-01) of
[ksh93](http://www.kornshell.com/),
formerly developed by AT&T Software Technology (AST).
The sources in this repository were extracted from the
Github [AST repository](https://github.com/att/ast)
which is no longer under active development.

To see what's fixed, see [NEWS](https://github.com/modernish/ksh/blame/93u%2Bm/NEWS)
and click on commit messages for full details.

To see what's left to fix, see [TODO](./TODO).

## Policy

1. No new features. Bug fixes only.
2. No major rewrites. No refactoring code that is not fully understood.
3. No changes in documented behaviour, except if required for compliance with the
   [POSIX shell language standard](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
   which David Korn [intended](http://www.kornshell.com/info/) for ksh to follow.
4. No 100% bug compatibility. Broken and undocumented behaviour gets fixed.
5. No bureaucracy, no formalities. Just fix it, or report it: create issues,
   send pull requests. Every interested party is invited to contribute.
6. To help increase everyone's understanding of this code base, fixes and
   significant changes should be fully documented in commit messages.

## Why?

Between 2017 and 2020 there was an ultimately unsuccessful
[attempt](https://github.com/att/ast/tree/2020.0.1)
to breathe new life into the KornShell by extensively refactoring the last
unstable AST beta version (93v-).
While that ksh2020 branch is now abandoned and still has many critical bugs,
it also had a lot of bugs fixed. More importantly, the AST issue tracker
now contains a lot of documentation on how to fix those bugs, which makes
it possible to backport many of them to the last stable release instead.

In February 2020, having concluded the AST 93v- beta was too broken to
base new work on, others decided to start a new fork based on the last stable
93u+ 2012-08-01 release. Unfortunately, as of May 2020, the new
[ksh-community](https://github.com/ksh-community/ksh/)
organisation is yet to see any significant activity three months after its
bootstrapping. I hope that will change; this fork is not intended as hostile.

The last stable ksh93 release from 2012 is the least buggy release currently
available, but it still has many serious bugs. So it is well past time to
start fixing those bugs, leave the rest of the code alone, and get an
improved release out there. Hence this fork of the ksh-community branch.

For more details regarding the origin of this repository, have a look at
[docs/repo-boostrap.md](./docs/repo-boostrap.md).

## Build

After cloning this repo, cd to the top directory of it and run:
```
./bin/package make
```
If you have trouble or want to tune the binaries, you may pass additional
compiler and linker flags by appending it to the command shown above. E.g.:
```
./bin/package make \
    SHELL=/bin/bash CCFLAGS="-xc99 -D_XPG6 -m64 -xO4" LDFLAGS="-m64"
```
For more information run
```sh
        bin/package help
```
Many other commands in this repo self-document via the `--help`, `--man` and
`--html` options; those that do have no separate manual page.

## Test

After compiling, you can run the regression tests.
Start by reading the information printed by:
```sh
./bin/shtests --man
```
Note that several regression tests are known to fail or crash as of the last
official 2012-08-01 release and some of the failures have not been fixed yet.
