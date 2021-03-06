/***********************************************************************
*                                                                      *
*               This software is part of the ast package               *
*          Copyright (c) 1982-2012 AT&T Intellectual Property          *
*                      and is licensed under the                       *
*                 Eclipse Public License, Version 1.0                  *
*                    by AT&T Intellectual Property                     *
*                                                                      *
*                A copy of the License is available at                 *
*          http://www.eclipse.org/org/documents/epl-v10.html           *
*         (with md5 checksum b35adb5213ca9657e911e9befb180842)         *
*                                                                      *
*              Information and Software Systems Research               *
*                            AT&T Research                             *
*                           Florham Park NJ                            *
*                                                                      *
*                  David Korn <dgk@research.att.com>                   *
*                                                                      *
***********************************************************************/
#pragma prototyped
#include	"defs.h"
#include	<signal.h>
#include	"FEATURE/options"
#include	"FEATURE/dynamic"

/*
 * This is the table of built-in aliases.  These should be exported.
 */

const struct shtable2 shtab_aliases[] =
{
	"autoload",	NV_NOFREE,		"typeset -fu",
	"compound",	NV_NOFREE|BLT_DCL,	"typeset -C",
	"float",	NV_NOFREE|BLT_DCL,	"typeset -lE",
	"functions",	NV_NOFREE,		"typeset -f",
	"history",	NV_NOFREE,		"hist -l",
	"integer",	NV_NOFREE|BLT_DCL,	"typeset -li",
	"nameref",	NV_NOFREE|BLT_DCL,	"typeset -n",
	"r",		NV_NOFREE,		"hist -s",
	"redirect",	NV_NOFREE,		"command exec",
	"source",	NV_NOFREE,		"command .",
#ifdef SIGTSTP
	"stop",		NV_NOFREE,		"kill -s STOP",
	"suspend", 	NV_NOFREE,		"kill -s STOP $$",
#endif /*SIGTSTP */
	"",		0,			(char*)0
};

