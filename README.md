# ksh93
This repository is used to maintain ksh93, formerly developed
by AT&T Software Technology (AST). The sources in this repository got
extracted from the
Github [AST repository](https://github.com/att/ast) that is no longer under
active development and are identical with the most
[recent commit](https://github.com/att/ast/commit/27e72175bde58da31c02b90e4ca179bf84310521).
The full AST respository contains, besides ksh, many more [POSIX] tools (e.g. cpp, nmake, pax, ...), which are not maintained here.

For more details regarding the history of this repository have a look at [docs/repo-boostrap.md](./docs/repo-boostrap.md) .

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

## Test
After compiling, you can run the regression tests.
Start by reading the information printed by:
```sh
./bin/shtests --man
```
Note that several regression tests are known to fail or crash as of the last
official 2012-08-01 release and some of the failures have not been fixed yet.
