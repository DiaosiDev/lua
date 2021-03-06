# Copyright (C) 2005-2009, Parrot Foundation.
# $Id$

#
#
#   Lexer module
#

package Lua::lexer;

use strict;
use warnings;

#use Math::BigFloat;

sub _DoubleQuoteStringLexer {
    my ($parser) = @_;
    my $str    = q{};
    my $type   = 'STRING';

    while ( $parser->YYData->{INPUT} ) {

        for ( $parser->YYData->{INPUT} ) {

            s/^\"//
                and return ( $type, $str );

            s/^([^"\\]+)//
                and $str .= $1, last;

            s/^\\([\\"'])//
                and $str .= $1,    # backslash, quotation mark, apostrophe
                last;
            s/^\\a//
                and $str .= "\a",    # bell
                last;
            s/^\\b//
                and $str .= "\b",    # backspace
                last;
            s/^\\f//
                and $str .= "\f",    # form feed
                last;
            s/^\\n//
                and $str .= "\n",    # new line
                last;
            s/^\\r//
                and $str .= "\r",    # carriage return
                last;
            s/^\\t//
                and $str .= "\t",    # horizontal tab
                last;
            s/^\\v//
                and $str .= "\x0b",    # vertical tab
                last;
            s/^\\([0-9]{1,3})//
                and $str .= chr $1, last;

            s/^\\//
                and $parser->Error("Invalid escape sequence $_ .\n"), last;
        }
    }

    $parser->Error("Untermined string.\n");
    $parser->YYData->{lineno}++;
    return ( $type, $str );
}

sub _SingleQuoteStringLexer {
    my ($parser) = @_;
    my $str    = q{};
    my $type   = 'STRING';

    while ( $parser->YYData->{INPUT} ) {

        for ( $parser->YYData->{INPUT} ) {

            s/^'//
                and return ( $type, $str );

            s/^([^'\\]+)//
                and $str .= $1, last;

            s/^\\([\\"'])//
                and $str .= $1,    # backslash, quotation mark, apostrophe
                last;
            s/^\\a//
                and $str .= "\a",    # bell
                last;
            s/^\\b//
                and $str .= "\b",    # backspace
                last;
            s/^\\f//
                and $str .= "\f",    # form feed
                last;
            s/^\\n//
                and $str .= "\n",    # new line
                last;
            s/^\\r//
                and $str .= "\r",    # carriage return
                last;
            s/^\\t//
                and $str .= "\t",    # horizontal tab
                last;
            s/^\\v//
                and $str .= "\x0b",    # vertical tab
                last;
            s/^\\([0-9]{1,3})//
                and $str .= chr $1, last;

            s/^\\//
                and $parser->Error("Invalid escape sequence $_ .\n"), last;
        }
    }

    $parser->Error("Untermined string.\n");
    $parser->YYData->{lineno}++;
    return ( $type, $str );
}

sub _LongStringLexer {
    my ($parser, $level) = @_;
    my $str     = q{};
    my $type    = 'STRING';

    $_ = $parser->YYData->{INPUT};
    s/^\n//
        and $parser->YYData->{lineno}++;

    while (1) {
        $parser->YYData->{INPUT}
            or $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
            or last;

        for ( $parser->YYData->{INPUT} ) {

            s/^(\n)//
                and $parser->YYData->{lineno}++, $str .= $1, last;

            s/^\]$level\]//
                and return ( $type, $str );

            s/^(.)//
                and $str .= $1, last;
        }
    }

    $parser->Error("Untermined raw string.\n");
    $parser->YYData->{lineno}++;
    return ( $type, $str );
}

sub _Identifier {
    my ($parser, $idf) = @_;

    if ( exists $parser->YYData->{keyword}{$idf} ) {
        return ( $parser->YYData->{keyword}{$idf}, $idf );
    }
    return ( 'NAME', $idf );
}

sub _LongCommentLexer {
    my ($parser, $level) = @_;

    while (1) {
        $parser->YYData->{INPUT}
            or $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
            or return;

        for ( $parser->YYData->{INPUT} ) {
            s/^\n//
                and $parser->YYData->{lineno}++, last;
            s/^\]$level\]//
                and return;
            s/^.//
                and last;
        }
    }
}

sub Lexer {
    my ($parser) = @_;

    while (1) {
        $parser->YYData->{INPUT}
            or $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
            or return ( q{}, undef );

        for ( $parser->YYData->{INPUT} ) {

            if ( $parser->YYData->{shebang} ) {
                $parser->YYData->{shebang} = undef;
                s/^#(.*)\n//    # Shebang
                    and $parser->YYData->{lineno}++, last;
            }

            s/^[ \r\t\f\013]+//;    # Whitespace
            s/^\n//
                and $parser->YYData->{lineno}++, last;

            s/^\-\-\[(=*)\[//       # LongComment
                and _LongCommentLexer($parser, $1), last;
            s/^\-\-(.*)\n//         # ShortComment
                and $parser->YYData->{lineno}++, last;

            s/^(0[Xx])([0-9A-Fa-f]+)//
                and return ( 'NUMBER', hex($2) );

            s/^(\d+(\.\d*)?|\.\d+)([Ee][+\-]?\d+)?//

                #                and return ('NUMBER', new Math::BigFloat($1));
                and return ( 'NUMBER', $1 . ( $3 || q{} ) );

            s/^\"//
                and return _DoubleQuoteStringLexer($parser);

            s/^\'//
                and return _SingleQuoteStringLexer($parser);

            s/^\[(=*)\[//
                and return _LongStringLexer($parser, $1);

            s/^([A-Z_a-z][0-9A-Z_a-z]*)//
                and return _Identifier($parser, $1);

            s/^(\.\.\.)//
                and return ( $1, $1 );
            s/^(\.\.)//
                and return ( $1, $1 );
            s/^(<=)//
                and return ( $1, $1 );
            s/^(>=)//
                and return ( $1, $1 );
            s/^(==)//
                and return ( $1, $1 );
            s/^(~=)//
                and return ( $1, $1 );

            s/^([\{\}\(\)\[\]\.;,<>\+\-\*\/%\^#:=])//
                and return ( $1, $1 );    # punctuator

            s/^([\S]+)//
                and $parser->Error("lexer error $1.\n"), last;
        }
    }
}

sub InitLexico {
    my ($parser) = @_;

    my %keywords = (
        'and'      => 'AND',
        'break'    => 'BREAK',
        'do'       => 'DO',
        'else'     => 'ELSE',
        'elseif'   => 'ELSEIF',
        'end'      => 'END',
        'false'    => 'FALSE',
        'for'      => 'FOR',
        'function' => 'FUNCTION',
        'if'       => 'IF',
        'in'       => 'IN',
        'local'    => 'LOCAL',
        'nil'      => 'NIL',
        'not'      => 'NOT',
        'or'       => 'OR',
        'repeat'   => 'REPEAT',
        'return'   => 'RETURN',
        'then'     => 'THEN',
        'true'     => 'TRUE',
        'until'    => 'UNTIL',
        'while'    => 'WHILE',
    );

    $parser->YYData->{keyword} = \%keywords;
    return;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

