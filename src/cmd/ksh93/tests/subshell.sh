########################################################################
#                                                                      #
#               This software is part of the ast package               #
#          Copyright (c) 1982-2012 AT&T Intellectual Property          #
#                      and is licensed under the                       #
#                 Eclipse Public License, Version 1.0                  #
#                    by AT&T Intellectual Property                     #
#                                                                      #
#                A copy of the License is available at                 #
#          http://www.eclipse.org/org/documents/epl-v10.html           #
#         (with md5 checksum b35adb5213ca9657e911e9befb180842)         #
#                                                                      #
#              Information and Software Systems Research               #
#                            AT&T Research                             #
#                           Florham Park NJ                            #
#                                                                      #
#                  David Korn <dgk@research.att.com>                   #
#                                                                      #
########################################################################
function err_exit
{
	print -u2 -n "\t"
	print -u2 -r ${Command}[$1]: "${@:2}"
	(( Errors+=1 ))
}
alias err_exit='err_exit $LINENO'

Command=${0##*/}
integer Errors=0
typeset -F SECONDS  # for fractional seconds in PS4

tmp=$(
	d=${TMPDIR:-/tmp}/ksh93.subshell.$$.${RANDOM:-0}
	mkdir -m700 -- "$d" && CDPATH= cd -P -- "$d" && pwd
) || {
	err_exit 'mkdir failed'
	exit 1
}
trap 'cd / && rm -rf "$tmp"' EXIT

builtin getconf
bincat=$(PATH=$(getconf PATH) whence -p cat)
binecho=$(PATH=$(getconf PATH) whence -p echo)
# make an external 'sleep' command that supports fractional seconds
binsleep=$tmp/.sleep.sh  # hide to exclude from simple wildcard expansion
cat >"$binsleep" <<EOF
#!$SHELL
sleep "\$@"
EOF
chmod +x "$binsleep"

z=()
z.foo=( [one]=hello [two]=(x=3 y=4) [three]=hi)
z.bar[0]=hello
z.bar[2]=world
z.bar[1]=(x=4 y=5)
val='(
	typeset -a bar=(
		[0]=hello
		[2]=world
		[1]=(
			x=4
			y=5
		)
	)
	typeset -A foo=(
		[one]=hello
		[three]=hi
		[two]=(
			x=3
			y=4
		)
	)
)'
[[ $z == "$val" ]] || err_exit 'compound variable with mixed arrays not working'
z.bar[1]=yesyes
[[ ${z.bar[1]} == yesyes ]] || err_exit 'reassign of index array compound variable fails'
z.bar[1]=(x=12 y=5)
[[ ${z.bar[1]} == $'(\n\tx=12\n\ty=5\n)' ]] || err_exit 'reassign array simple to compound variable fails'
eval val="$z"
(
	z.foo[three]=good
	[[ ${z.foo[three]} == good ]] || err_exit 'associative array assignment in subshell not working'
)
[[ $z == "$val" ]] || err_exit 'compound variable changes after associative array assignment'
eval val="$z"
(
	z.foo[two]=ok
	[[ ${z.foo[two]} == ok ]] || err_exit 'associative array assignment to compound variable in subshell not working'
	z.bar[1]=yes
	[[ ${z.bar[1]} == yes ]] || err_exit 'index array assignment to compound variable in subshell not working'
)
[[ $z == "$val" ]] || err_exit 'compound variable changes after associative array assignment'

x=(
	foo=( qqq=abc rrr=def)
	bar=( zzz=no rst=fed)
)
eval val="$x"
(
	unset x.foo
	[[ ${x.foo.qqq} ]] && err_exit 'x.foo.qqq should be unset'
	x.foo=good
	[[ ${x.foo} == good ]] || err_exit 'x.foo should be good'
)
[[ $x == "$val" ]] || err_exit 'compound variable changes after unset leaves'
unset l
(
	l=( a=1 b="BE" )
)
[[ ${l+foo} != foo ]] || err_exit 'l should be unset'

TEST_notfound=notfound
while	whence $TEST_notfound >/dev/null 2>&1
do	TEST_notfound=notfound-$RANDOM
done


integer BS=1024 nb=64 ss=60 bs no
for bs in $BS 1
do	$SHELL -c '
		{
			sleep '$ss'
			kill -KILL $$
		} &
		set -- $(printf %.'$(($BS*$nb))'c x | dd bs='$bs')
		print ${#1}
		kill $!
	' > $tmp/sub 2>/dev/null
	no=$(<$tmp/sub)
	(( no == (BS * nb) )) || err_exit "shell hangs on command substitution output size >= $BS*$nb with write size $bs -- expected $((BS*nb)), got ${no:-0}"
done
# this time with redirection on the trailing command
for bs in $BS 1
do	$SHELL -c '
		{
			sleep 2
			sleep '$ss'
			kill -KILL $$
		} &
		set -- $(printf %.'$(($BS*$nb))'c x | dd bs='$bs' 2>/dev/null)
		print ${#1}
		kill $!
	' > $tmp/sub 2>/dev/null
	no=$(<$tmp/sub)
	(( no == (BS * nb) )) || err_exit "shell hangs on command substitution output size >= $BS*$nb with write size $bs and trailing redirection -- expected $((BS*nb)), got ${no:-0}"
done

# exercise command substitutuion trailing newline logic w.r.t. pipe vs. tmp file io

set -- \
	'post-line print'								\
	'$TEST_unset; ($TEST_fork; print 1); print'					\
	1										\
	'pre-line print'								\
	'$TEST_unset; ($TEST_fork; print); print 1'					\
	$'\n1'										\
	'multiple pre-line print'							\
	'$TEST_unset; ($TEST_fork; print); print; ($TEST_fork; print 1); print'		\
	$'\n\n1'									\
	'multiple post-line print'							\
	'$TEST_unset; ($TEST_fork; print 1); print; ($TEST_fork; print); print'		\
	1										\
	'intermediate print'								\
	'$TEST_unset; ($TEST_fork; print 1); print; ($TEST_fork; print 2); print'	\
	$'1\n\n2'									\
	'simple variable'								\
	'$TEST_unset; ($TEST_fork; l=2; print "$l"); print $l'				\
	2										\
	'compound variable'								\
	'$TEST_unset; ($TEST_fork; l=(a=2 b="BE"); print "$l"); print $l'		\
	$'(\n\ta=2\n\tb=BE\n)'								\

export TEST_fork TEST_unset

while	(( $# >= 3 ))
do	txt=$1
	cmd=$2
	exp=$3
	shift 3
	for TEST_unset in '' 'unset var'
	do	for TEST_fork in '' 'ulimit -c 0'
		do	for TEST_shell in "eval" "$SHELL -c"
			do	if	! got=$($TEST_shell "$cmd")
				then	err_exit "${TEST_shell/*-c/\$SHELL -c} ${TEST_unset:+unset }${TEST_fork:+fork }$txt print failed"
				elif	[[ "$got" != "$exp" ]]
				then	EXP=$(printf %q "$exp")
					GOT=$(printf %q "$got")
					err_exit "${TEST_shell/*-c/\$SHELL -c} ${TEST_unset:+unset }${TEST_fork:+fork }$txt command substitution failed -- expected $EXP, got $GOT"
				fi
			done
		done
	done
done

r=$( ($SHELL -c '
	{
		sleep 32
		kill -KILL $$
	} &
	for v in $(set | sed "s/=.*//")
	do	command unset $v
	done
	typeset -Z5 I
	for ((I = 0; I < 1024; I++))
	do	eval A$I=1234567890
	done
	a=$(set 2>&1)
	print ok
	kill -KILL $!
') 2>/dev/null)
[[ $r == ok ]] || err_exit "large subshell command substitution hangs"

for TEST_command in '' $TEST_notfound
do	for TEST_exec in '' 'exec'
	do	for TEST_fork in '' 'ulimit -c 0;'
		do	for TEST_redirect in '' '>/dev/null'
			do	for TEST_substitute in '' ': $'
				do

	TEST_test="$TEST_substitute($TEST_fork $TEST_exec $TEST_command $TEST_redirect)"
	[[ $TEST_test == '('*([[:space:]])')' ]] && continue
	r=$($SHELL -c '
		{
			sleep 2
			kill -KILL $$
		} &
		{ '"$TEST_test"'; } 2>/dev/null
		kill $!
		print ok
		')
	[[ $r == ok ]] || err_exit "shell hangs on $TEST_test"

				done
			done
		done
	done
done

$SHELL -c '( autoload xxxxx);print -n' ||  err_exit 'autoloaded functions in subshells can cause failure'
foo=$($SHELL  <<- ++EOF++
	(trap 'print bar' EXIT;print -n foo)
	++EOF++
)
[[ $foo == foobar ]] || err_exit 'trap on exit when last commands is subshell is not triggered'

err=$(
	$SHELL  2>&1  <<- \EOF
	        date=$(whence -p date)
	        function foo
	        {
	                x=$( $date > /dev/null 2>&1 ;:)
	        }
		# consume almost all fds to push the test to the fd limit #
		integer max=$(ulimit --nofile)
		(( max -= 6 ))
		for ((i=20; i < max; i++))
		do	exec {i}>&1
		done
	        for ((i=0; i < 20; i++))
	        do      y=$(foo)
	        done
	EOF
) || {
	err=${err%%$'\n'*}
	err=${err#*:}
	err=${err##[[:space:]]}
	err_exit "nested command substitution with redirections failed -- $err"
}

exp=0
$SHELL -c $'
	function foobar
	{
		print "hello world"
	}
	[[ $(getopts \'[+?X\ffoobar\fX]\' v --man 2>&1) == *"Xhello worldX"* ]]
	exit '$exp$'
'
got=$?
[[ $got == $exp ]] || err_exit "getopts --man runtime callout with nonzero exit terminates shell -- expected '$exp', got '$got'"
exp=ok
got=$($SHELL -c $'
	function foobar
	{
		print "hello world"
	}
	[[ $(getopts \'[+?X\ffoobar\fX]\' v --man 2>&1) == *"Xhello worldX"* ]]
	print '$exp$'
')
[[ $got == $exp ]] || err_exit "getopts --man runtime callout with nonzero exit terminates shell -- expected '$exp', got '$got'"

# command substitution variations #
set -- \
	'$('			')'		\
	'${ '			'; }'		\
	'$(ulimit -c 0; '	')'		\
	'$( ('			') )'		\
	'${ ('			'); }'		\
	'`'			'`'		\
	'`('			')`'		\
	'`ulimit -c 0; '	'`'		\
	# end of table #
exp=ok
testcase[1]='
	if	%sexpr "NOMATCH" : ".*Z" >/dev/null%s
	then	print error
	else	print ok
	fi
	exit %s
'
testcase[2]='
	function bar
	{
		pipeout=%1$sprintf Ok | tr O o%2$s
		print $pipeout
		return 0
	}
	foo=%1$sbar%2$s || foo="exit status $?"
	print $foo
	exit %3$s
'
while	(( $# >= 2 ))
do	for ((TEST=1; TEST<=${#testcase[@]}; TEST++))
	do	body=${testcase[TEST]}
		for code in 0 2
		do	got=${ printf "$body" "$1" "$2" "$code" | $SHELL 2>&1 }
			status=$?
			if	(( status != code ))
			then	err_exit "test $TEST '$1...$2 exit $code' failed -- exit status $status, expected $code"
			elif	[[ $got != $exp ]]
			then	err_exit "test $TEST '$1...$2 exit $code' failed -- got '$got', expected '$exp'"
			fi
		done
	done
	shift 2
done

# the next tests loop on all combinations of
#	{ SUB CAT INS TST APP } X { file-sizes }
# where the file size starts at 1Ki and doubles up to and including 1Mi
#
# the tests and timeouts are done in async subshells to prevent
# the test harness from hanging

SUB=(
	( BEG='$( '	END=' )'	)
	( BEG='${ '	END='; }'	)
)
CAT=(  cat  $bincat  )
INS=(  ""  "builtin cat; "  "builtin -d cat $bincat; "  ": > /dev/null; "  )
APP=(  ""  "; :"  )
TST=(
	( CMD='print foo | $cat'			EXP=3		)
	( CMD='$cat < $tmp/lin'						)
	( CMD='cat $tmp/lin | $cat'					)
	( CMD='read v < $tmp/buf; print $v'		LIM=4*1024	)
	( CMD='cat $tmp/buf | read v; print $v'		LIM=4*1024	)
)

if	cat /dev/fd/3 3</dev/null >/dev/null 2>&1 || whence mkfifo > /dev/null
then	T=${#TST[@]}
	TST[T].CMD='$cat <(print foo)'
	TST[T].EXP=3
fi

# prime the two data files to 512 bytes each
# $tmp/lin has newlines every 16 bytes and $tmp/buf has no newlines
# the outer loop doubles the file size at top

buf=$'1234567890abcdef'
lin=$'\n1234567890abcde'
for ((i=0; i<5; i++))
do	buf=$buf$buf
	lin=$lin$lin
done
print -n "$buf" > $tmp/buf
print -n "$lin" > $tmp/lin

unset SKIP
for ((n=1024; n<=1024*1024; n*=2))
do	cat $tmp/buf $tmp/buf > $tmp/tmp
	mv $tmp/tmp $tmp/buf
	cat $tmp/lin $tmp/lin > $tmp/tmp
	mv $tmp/tmp $tmp/lin
	for ((S=0; S<${#SUB[@]}; S++))
	do	for ((C=0; C<${#CAT[@]}; C++))
		do	cat=${CAT[C]}
			for ((I=0; I<${#INS[@]}; I++))
			do	for ((A=0; A<${#APP[@]}; A++))
				do	for ((T=0; T<${#TST[@]}; T++))
					do	#undent...#

	if	[[ ! ${SKIP[S][C][I][A][T]} ]]
	then	eval "{ x=${SUB[S].BEG}${INS[I]}${TST[T].CMD}${APP[A]}${SUB[S].END}; print \${#x}; } >\$tmp/out &"
		m=$!
		{ sleep 4; kill -9 $m; } &
		k=$!
		wait $m
		h=$?
		kill -9 $k
		{ wait $k; } 2>/dev/null  # suppress 'wait: $pid: Killed'
		got=$(<$tmp/out)
		if	[[ ! $got ]] && (( h ))
		then	got=HUNG
		fi
		if	[[ ${TST[T].EXP} ]]
		then	exp=${TST[T].EXP}
		else	exp=$n
		fi
		if	[[ $got != $exp ]]
		then	# on failure skip similar tests on larger files sizes #
			SKIP[S][C][I][A][T]=1
			siz=$(printf $'%#i' $exp)
			cmd=${TST[T].CMD//\$cat/$cat}
			cmd=${cmd//\$tmp\/buf/$siz.buf}
			cmd=${cmd//\$tmp\/lin/$siz.lin}
			err_exit "'x=${SUB[S].BEG}${INS[I]}${cmd}${APP[A]}${SUB[S].END} && print \${#x}' failed -- expected '$exp', got '$got'"
		elif	[[ ${TST[T].EXP} ]] || (( TST[T].LIM >= n ))
		then	SKIP[S][C][I][A][T]=1
		fi
	fi

						#...indent#
					done
				done
			done
		done
	done
done

# specifics -- there's more?

{
	cmd='{ exec 5>/dev/null; print "$(set +x; eval ls -d . 2>&1 1>&5)"; } >$tmp/out &'
	eval $cmd
	m=$!
	{ sleep 4; kill -9 $m; } &
	k=$!
	wait $m
	h=$?
	kill -9 $k
	wait $k
	got=$(<$tmp/out)
} 2>/dev/null
exp=''
if	[[ ! $got ]] && (( h ))
then	got=HUNG
fi
if	[[ $got != $exp ]]
then	err_exit "eval '$cmd' failed -- expected '$exp', got '$got'"
fi

float t1=$SECONDS

$SHELL -c '( "$1" 5 </dev/null >/dev/null 2>&1 & );exit 0' x "$binsleep" | cat 
(( (SECONDS-t1) > 4 )) && err_exit '/bin/sleep& in subshell hanging'
((t1=SECONDS))

$SHELL -c '( sleep 5 </dev/null >/dev/null 2>&1 & );exit 0' | cat 
(( (SECONDS-t1) > 4 )) && err_exit 'sleep& in subshell hanging'

exp=HOME=$HOME
( HOME=/bin/sh )
got=$(env | grep ^HOME=)
[[ $got == "$exp" ]] ||  err_exit "( HOME=/bin/sh ) cleanup failed -- expected '$exp', got '$got'"

cmd='echo $((case x in x)echo ok;esac);:)'
exp=ok
got=$($SHELL -c "$cmd" 2>&1)
[[ $got == "$exp" ]] ||  err_exit "'$cmd' failed -- expected '$exp', got '$got'"

cmd='eval '\''for i in 1 2; do eval "\"\$binecho\" x"; done'\'
exp=$'x\nx'
got=$(export binecho; $SHELL -c "$cmd")
if	[[ $got != "$exp" ]]
then	EXP=$(printf %q "$exp")
	GOT=$(printf %q "$got")
	err_exit "'$cmd' failed -- expected $EXP, got $GOT"
fi

(
$SHELL -c 'sleep 20 & pid=$!; { x=$( ( seq 60000 ) );kill -9 $pid;}&;wait $pid'
) 2> /dev/null
(( $? )) ||  err_exit 'nested command substitution with large output hangs'

(.sh.foo=foobar)
[[ ${.sh.foo} == foobar ]] && err_exit '.sh subvariables in subshells remain set'
[[ $(export bincat; $SHELL -c 'print 1 | : "$("$bincat" <("$bincat"))"') ]] && err_exit 'process substitution not working correctly in subshells'

# config hang bug
integer i
for ((i=1; i < 1000; i++))
do	typeset foo$i=$i
done
{
    : $( (ac_space=' '; set | grep ac_space) 2>&1) 
} < /dev/null | cat > /dev/null &
sleep  1.5
if	kill -KILL $! 2> /dev/null
then	err_exit 'process timed out with hung comsub'
fi
wait $! 2> /dev/null
(( $? > 128 )) && err_exit 'incorrect exit status with comsub' 

$SHELL 2> /dev/null -c '[[ ${ print foo },${ print bar } == foo,bar ]]' || err_exit  '${ print foo },${ print bar } not working'
$SHELL 2> /dev/null -c '[[ ${ print foo; },${ print bar } == foo,bar ]]' || err_exit  '${ print foo; },${ print bar } not working'

src=$'true 2>&1\n: $(true | true)\n: $(true | true)\n: $(true | true)\n'$(whence -p true)
exp=ok
got=$( $SHELL -c "(eval '$src'); echo $exp" )
[[ $got == "$exp" ]] || err_exit 'subshell eval of pipeline clobbers stdout'

x=$( { time $SHELL -c date >| /dev/null;} 2>&1)
[[ $x == *real*user*sys* ]] || err_exit 'time { ...;} 2>&1 in $(...) fails'

x=$($SHELL -c '( function fx { export X=123;  } ; fx; ); echo $X')
[[ $x == 123 ]] && err_exit 'global variables set from with functions inside a
subshell can leave side effects in parent shell'

date=$(whence -p date)
err() { return $1; }
( err 12 ) & pid=$!
: $( $date)
wait $pid
[[ $? == 12 ]] || err_exit 'exit status from subshells not being preserved'

if	cat /dev/fd/3 3</dev/null >/dev/null 2>&1 || whence mkfifo > /dev/null
then	x="$(sed 's/^/Hello /' <(print "Fred" | sort))"
	[[ $x == 'Hello Fred' ]] || err_exit  "process substitution of pipeline in command substitution not working"
fi

{
$SHELL <<- \EOF
	function foo
	{
		integer i
		print -u2 foobar
		for	((i=0; i < 8000; i++))
		do	print abcdefghijk
		done
		print -u2 done
	}
	out=$(eval "foo | cat" 2>&1)
	(( ${#out} == 96011 )) || err_exit "\${#out} is ${#out} should be 96011"
EOF
} & pid=$!
$SHELL -c "{ sleep .4 && kill $pid ;}" 2> /dev/null
(( $? == 0 )) &&  err_exit 'process has hung'

{
x=$( $SHELL  <<- \EOF
	function func1 { typeset IFS; : $(func2); print END ;}
	function func2 { IFS="BAR"; }
	func1
	func1
EOF
)
} 2> /dev/null
[[ $x == $'END\nEND' ]] || err_exit 'bug in save/restore of IFS in subshell'

true=$(whence -p true)
date=$(whence -p date)
tmpf=$tmp/foo
function fun1
{
	$true
	cd - >/dev/null 2>&1
	print -u2 -- "$($date) SUCCESS"
}

print -n $(fun1 2> $tmpf)
[[  $(< $tmpf) == *SUCCESS ]] || err_exit 'standard error output lost with command substitution'


tmpfile=$tmp/foo
cat > $tmpfile <<-\EOF
	$SHELL -c 'function g { IFS= ;};function f { typeset IFS;(g);: $V;};f;f'
	EOF
$SHELL 2> /dev/null "$tmpfile" || err_exit 'IFS in subshell causes core dump'

unset i
if      [[ -d /dev/fd ]]
then    integer i
        for ((i=11; i < 29; i++))
        do      if      ! [[ -r /dev/fd/$i  || -w /dev/fd/$i ]]
                then    a=$($SHELL -c "[[ -r /dev/fd/$i || -w /dev/fd/$i ]]")
                        (( $? )) || err_exit "file descriptor $i not close on exec"
                fi
        done
fi

trap USR1 USR1
trap ERR ERR
[[ $(trap -p USR1) == USR1 ]] || err_exit 'trap -p USR1 in subshell not working'
[[ $(trap -p ERR) == ERR ]] || err_exit 'trap -p ERR in subshell not working'
[[ $(trap -p) == *USR* ]] || err_exit 'trap -p in subshell does not contain USR'
[[ $(trap -p) == *ERR* ]] || err_exit 'trap -p in subshell does not contain ERR'
trap - USR1 ERR

( PATH=/bin:/usr/bin
dot=$(cat <<-EOF
		$(ls -d .)
	EOF
) ) & sleep 1
if      kill -0 $! 2> /dev/null
then    err_exit  'command substitution containing here-doc with command substitution fails'
fi

printf=$(whence -p printf)
[[ $( { trap "echo foobar" EXIT; ( $printf ""); } & wait) == foobar ]] || err_exit  'exit trap not being invoked'

$SHELL 2> /dev/null -c '( PATH=/bin; set -o restricted) ; exit 0'  || err_exit 'restoring PATH when a subshell enables restricted exits not working'

$SHELL <<- \EOF
	wc=$(whence wc) head=$(whence head)
	print > /dev/null  $( ( $head -c 1 /dev/zero | ( $wc -c) 3>&1 ) 3>&1) &
	pid=$!
	sleep .2
	kill -9 $! 2> /dev/null && err_exit '/dev/zero in command substitution hangs'
	wait $!
EOF

for f in /dev/stdout /dev/fd/1
do	if	[[ -e $f ]]
	then	$SHELL -c "x=\$(command -p tee $f </dev/null 2>/dev/null)" || err_exit "$f in command substitution fails"
	fi
done

# ======
# Unsetting or redefining functions within subshells

# ...function can be unset in subshell

func() { echo mainfunction; }
(unset -f func; typeset -f func >/dev/null 2>&1) && err_exit 'function fails to be unset in subshell'
v=$(unset -f func; typeset -f func >/dev/null 2>&1) && err_exit 'function fails to be unset in comsub'
v=${ unset -f func 2>&1; } && ! typeset -f func >/dev/null 2>&1 || err_exit 'function unset fails to survive ${ ...; }'

# ...function can be redefined in subshell
func() { echo mainfunction; }
(func() { echo sub; }; [[ ${ func; } == sub ]]) || err_exit 'function fails to be redefined in subshell'
v=$(func() { echo sub; }; func) && [[ $v == sub ]] || err_exit 'function fails to be redefined in comsub'
v=${ { func() { echo sub; }; } 2>&1; } && [[ $(PATH=/dev/null func) == sub ]] \
	|| err_exit 'function redefine fails to survive ${ ...; }'

# ...some more fun from Stéphane Chazelas: https://github.com/att/ast/issues/73#issuecomment-384178095
a=$tmp/morefun.sh
cat >| "$a" <<EOF
true() { echo WRONG; }
(true() { echo ok; } && true && unset -f true && true) || false
# the extra '|| false' avoids optimising out the subshell
EOF
v=$("$SHELL" "$a") && [[ $v == ok ]] || err_exit 'fail: more fun 1'
v=$("$SHELL" -c "$(cat "$a")") && [[ $v == ok ]] || err_exit 'fail: more fun 2'
v=$("$SHELL" -c 'eval "$(cat "$1")"' x "$a") && [[ $v == ok ]] || err_exit "fail: more fun 3"
v=$("$SHELL" -c '. "$1"' x "$a") && [[ $v == ok ]] || err_exit "fail: more fun 4"

# ...multiple levels of subshell
func() { echo mainfunction; }
v=$(
	(
		func() { echo sub1; }
		(
			func() { echo sub2; }
			(
				func() { echo sub3; }
				func
				PATH=/dev/null
				unset -f func
				func 2>/dev/null
				(($? == 127)) && echo ok_nonexistent || echo fail_zombie
			)
			func
		)
		func
	)
	func
)
expect=$'sub3\nok_nonexistent\nsub2\nsub1\nmainfunction'
[[ $v == "$expect" ]] \
|| err_exit "multi-level subshell function failure (expected $(printf %q "$expect"), got $(printf %q "$v"))"

# ======
# Unsetting or redefining aliases within subshells

# ...alias can be unset in subshell

alias al="echo 'mainalias'"

(unalias al; alias al 2>/dev/null) && err_exit 'alias fails to be unset in subshell'

v=$(unalias al; alias al 2>/dev/null) && err_exit 'alias fails to be unset in comsub'

[[ $(eval 'al') == 'mainalias' ]] || err_exit 'main alias fails to survive unset in subshell(s)'

v=${ eval 'al'; unalias al 2>&1; } && [[ $v == 'mainalias' ]] && ! alias al 2>/dev/null \
|| err_exit 'main shell alias wrongly survives unset within ${ ...; }'

# ...alias can be redefined in subshell

alias al="echo 'mainalias'"

(alias al='echo sub'; [[ $(eval 'al') == sub ]]) || err_exit 'alias fails to be redefined in subshell'

v=$(alias al='echo sub'; eval 'al') && [[ $v == sub ]] || err_exit 'alias fails to be redefined in comsub'

[[ $(eval 'al') == 'mainalias' ]] || err_exit 'main alias fails to survive redefinition in subshell(s)'

v=${ eval 'al'; alias al='echo subshare'; } && [[ $v == 'mainalias' && $(eval 'al') == subshare ]] \
|| err_exit 'alias redefinition fails to survive ${ ...; }'

# ======
exit $((Errors<125?Errors:125))
