#! perl
# Copyright (C) 2007, The Perl Foundation.
# $Id$

=head1 NAME

t/standalone.t

=head1 SYNOPSIS

    % perl -I../lib -Ilua/t lua/t/standalone.t

=head1 DESCRIPTION

See "Lua 5.1 Reference Manual", section 6 "Lua Stand-alone",
L<http://www.lua.org/manual/5.1/manual.html#6>.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use Parrot::Test tests => 14;
use Test::More;

delete $ENV{LUA_INIT};
delete $ENV{TEST_PROG_ARGS};

language_output_is( 'lua', <<'CODE', <<'OUT', 'shebang' );
#!/usr/bin/env lua

print("Hello World")
CODE
Hello World
OUT

language_output_like( 'Lua_lex', <<'CODE', <<'OUT', 'shebang misplaced' );

#!/usr/bin/env lua
print("Hello World")
CODE
/^lua[^:]*: [^:]+:1: syntax error/
OUT

SKIP:
{
skip('only with an interpreter', 10) if (($ENV{PARROT_LUA_TEST_PROG} || q{}) eq 'luac.pl');

$ENV{LUA_INIT} = 'print "init"';
language_output_is( 'lua', <<'CODE', <<'OUT', 'LUA_INIT string' );
print("Hello World")
CODE
init
Hello World
OUT
delete $ENV{LUA_INIT};

$ENV{LUA_INIT} = 'error "init"';
language_output_like( 'lua', <<'CODE', <<'OUT', 'LUA_INIT error' );
print("Hello World")
CODE
/^lua[^:]*: [^:]+:\d+: init\nstack traceback:\n/
OUT
delete $ENV{LUA_INIT};

$ENV{LUA_INIT} = '?syntax error?';
language_output_like( 'lua', <<'CODE', <<'OUT', 'LUA_INIT bad string' );
print("Hello World")
CODE
/^lua[^:]*: /
OUT
delete $ENV{LUA_INIT};

unlink('../boot.lua') if ( -f '../boot.lua' );
open my $X, '>', '../boot.lua';
print {$X} "print 'boot from boot.lua by LUA_INIT'\n";
close $X;

$ENV{LUA_INIT} = '@boot.lua';
language_output_is( 'lua', <<'CODE', <<'OUT', 'LUA_INIT file' );
print("Hello World")
CODE
boot from boot.lua by LUA_INIT
Hello World
OUT

unlink('../boot.lua') if ( -f '../boot.lua' );
open $X, '>', '../boot.lua';
print {$X} '?syntax error?';
close $X;

$ENV{LUA_INIT} = '@boot.lua';
language_output_like( 'lua', <<'CODE', <<'OUT', 'LUA_INIT bad file' );
print("Hello World")
CODE
/^lua[^:]*: /
OUT

unlink('../boot.lua');

$ENV{LUA_INIT} = '@no_file.lua';
language_output_like( 'lua', <<'CODE', <<'OUT', 'LUA_INIT no file' );
print("Hello World")
CODE
/^lua[^:]*: cannot open no_file.lua: No such file or directory$/
OUT

delete $ENV{LUA_INIT};

$ENV{TEST_PROG_ARGS} = '-e"a=1" -e "print(a)"';
language_output_is( 'lua', undef, <<'OUT', '-e' );
1
OUT

$ENV{TEST_PROG_ARGS} = '-e"a=1" -e "print(a)"';
language_output_is( 'lua', <<'CODE', <<'OUT', '-e & script' );
print("Hello World")
CODE
1
Hello World
OUT

$ENV{TEST_PROG_ARGS} = '-v';
language_output_like( 'lua', undef, <<'OUT', '-v' );
/^Lua 5.1/
OUT

$ENV{TEST_PROG_ARGS} = '-v';
language_output_like( 'lua', <<'CODE', <<'OUT', '-v & script' );
print(arg[-1])
CODE
/^Lua 5.1.*\n-v$/
OUT

}

SKIP:
{
skip('only with Parrot', 2) unless (($ENV{PARROT_LUA_TEST_PROG} || 'lua.pbc') eq 'lua.pbc');

$ENV{TEST_PROG_ARGS} = '-lalarm';
language_output_is( 'lua', << 'CODE', << 'OUTPUT', '-lalarm' );
print(type(alarm))
CODE
function
OUTPUT

$ENV{TEST_PROG_ARGS} = '-l alarm';
language_output_is( 'lua', << 'CODE', << 'OUTPUT', '-l alarm' );
print(type(alarm))
CODE
function
OUTPUT

}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

