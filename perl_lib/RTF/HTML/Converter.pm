# Philippe Verdret 1998-1999
use strict;

package RTF::HTML::Converter;
$RTF::HTML::Converter::VERSION = '1.12';
use RTF::Control;
use RTF::HTML::Converter::ansi;
use RTF::HTML::Converter::charmap;

@RTF::HTML::Converter::ISA = qw(RTF::Control);

use constant TRACE                    => 0;
use constant LIST_TRACE               => 0;
use constant SHOW_STYLE_NOT_PROCESSED => 1;
use constant SHOW_STYLE               => 0;    # insert style name in the output
use constant SHOW_RTF_LINE_NUMBER     => 0;

use constant RTF_DEBUG => 0;

=head1 NAME

RTF::HTML::Converter - Perl extension for converting RTF into HTML

=head1 VERSION

version 1.12

=head1 DESCRIPTION

Perl extension for converting RTF into HTML

=head1 SYNOPSIS

	use strict;
	use RTF::HTML::Converter;

	my $object = RTF::HTML::Converter->new(

		output => \*STDOUT

	);

	$object->parse_stream( \*RTF_FILE );

OR

	use strict;
	use RTF::HTML::Converter;

	my $object = RTF::HTML::Converter->new(

		output => \$string

	);

	$object->parse_string( $rtf_data );

=head1 METHODS

=head2 new()

Constructor method. Currently takes one named parameter, C<output>,
which can either be a reference to a filehandle, or a reference to
a string. This is where our HTML will end up.

=head2 parse_stream()

Read RTF in from a filehandle, and start processing it. Pass me
a reference to a filehandle.

=head2 parse_string()

Read RTF in from a string, and start processing it. Pass me a string.

=head1 JUST SO YOU KNOW

You can mix-and-match your output and input methods - nothing to stop
you outputting to a string when you've read from a filehandle...

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>, originally by Philippe Verdret

=head1 COPYRIGHT

Copyright 2004 B<Pete Sergeant>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CREDITS

This work was carried out under a grant generously provided by The Perl Foundation -
give them money!


=cut

# Symbol exported by the RTF::Ouptut module:
# %info: informations of the {\info ...}
# %par_props: paragraph properties
# $style: name of the current style or pseudo-style
# $event: start and end on the 'document' event
# $text: text associated to the current style
# %symbol: symbol translations
# %do_on_control: routines associated to RTF controls
# %do_on_event: routines associated to events
# output(): a stack oriented output routine (don't use print())

my $START_NEW_PARA = 1;    # some actions to do at the beginning of a new para

###########################################################################
my $N            = "\n";   # Pretty-printing
                           # some output parameters
my $TITLE_FLAG   = 0;
my $LANG         = 'en';
my $TABLE_BORDER = 1;

my $CURRENT_LI = 0;        # current list indent
my @LIST_STACK = ();       # stack of opened lists
my %LI_LEVEL   = ();       # li -> list level

my %charmap_defaults = map( { sprintf( "%02x", $_ ) => "&#$_;" } ( 0 .. 255 ) );

my %tag_counter = (); # Attempt to only close tags that might be open

my %PAR_ALIGN = qw(
    qc CENTER
    ql LEFT
    qr RIGHT
    qj LEFT
);
# here put your style mappings
my %STYLES = (
    'Normal'   => 'p',
    'Abstract' => 'Blockquote',
    'PACSCode' => 'Code',
    #'AuthGrp' => '',
    'Section'   => 'H1',
    'heading 1' => 'H1',
    'heading 2' => 'H2',
    'heading 3' => 'H3',
    'heading 4' => 'H4',
    'heading 5' => 'H5',
    'heading 6' => 'H6',
    'Code'      => 'pre',
    'par'       => 'p',     # default value
);
# list names -> level
my %UL_STYLES = (
    'toc 1' => 1,
    'toc 2' => 2,
    'toc 3' => 3,
    'toc 4' => 4,
    'toc 5' => 5, );

# not used
my %UL_TYPES = qw(b7 disk
    X square
    Y circle
);

my %OL_STYLES = ();
# not used
my %OL_TYPES = (
    'pncard'  => '1',    # Cardinal numbering: One, Two, Three
    'pndec'   => '1',    # Decimal numbering: 1, 2, 3
    'pnucltr' => 'A',    # Uppercase alphabetic numbering
    'pnlcltr' => 'a',    # lowercase alphabetic numbering
    'pnucrm'  => 'I',    # Uppercase roman numbering
    'pnlcrm'  => 'i',    # Lowercase roman numbering
);
my $in_Field    = -1;    # nested links are illegal, not used
my $in_Bookmark = -1;    # nested links are illegal, not used

# This is truly nasty, but it's slightly nicer than what was there before
my $make_tag_handler = sub {
    my $tag_ = shift;
    return sub {
        $style = $tag_;
        if ( $event eq 'end' ) {
            if ( $tag_counter{ $style } ) {
                $tag_counter{ $style }--;
                output "</$style>"
            }
        } else {
            $tag_counter{ $style }++;
            output "<$style>";
        }
    }
};

%do_on_event = (
    'document' => sub {    # Special action
        %tag_counter = ();
        if ( $event eq 'start' ) {
            output
                qq@<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" []>$N<html>$N<body>$N@;
        } else {
            my $author  = $info{author};
            my $creatim = $info{creatim};
            my $revtim  = $info{revtim};

            my $tag;
            while (@LIST_STACK) {
                $tag = pop @LIST_STACK;
                output "</$tag>" . $N;
            }
            $style = 'p';

            if ( $LANG eq 'fr' ) {
                output "<$style><b>Auteur</b> : $author</$style>\n" if $author;
                output "<$style><b>Date de cr&eacute;ation</b> : $creatim</$style>\n"
                    if $creatim;
                output
                    "<$style><b>Date de modification</b> : $revtim</$style>\n"
                    if $revtim;
            } else {    # Default
                output "<$style><b>Author</b> : $author</$style>\n" if $author;
                output "<$style><b>Creation date</b>: $creatim</$style>\n"
                    if $creatim;
                output "<$style><b>Modification date</b>: $revtim</$style>\n"
                    if $revtim;
            }
            output "</body>\n</html>\n";
        }
    },
    # Table processing
    'table' => sub {    # end of table
        if ( $event eq 'end' ) {
            #print STDERR "end of table\n";
            $TABLE_BORDER ? output "<table BORDER>$N$text</table>$N" :
                output "<table>$N$text</table>$N";
        } else {
            #print STDERR "start of table\n";
            my $end;
            while (@LIST_STACK) {
                $end .= '</' . pop(@LIST_STACK) . '>' . $N;
            }
            output($end);
        }
    },
    'row' => sub {    # end of row
                      #my $char_props = $_[SELF]->force_char_props('end');
                      #output "$N<tr valign='top'>$text$char_props</tr>$N";
        if ( $event eq 'end' ) {
            output "$N<tr valign='top'>$N$text$N</tr>$N";
        } else {
            # not defined
        }
    },
    'cell' => sub {    # end of cell
        if ( $event eq 'end' ) {
            my $char_props = $_[SELF]->force_char_props('end');
            my $end;
            while (@LIST_STACK) {
                $end .= '</' . pop(@LIST_STACK) . '>' . $N;
            }
            output "<td>$text$char_props$end</td>$N";
        } else {
            # not defined
        }
    },
    # PARAGRAPH STYLES
    #'Normal' => sub {},		# create one entry per style name???
    'par' => sub {    # Default rule: if no entry for a paragraph style
                      # Paragraph styles
                      #print STDERR "$style\n" if LIST_TRACE;
        return output($text) unless $text =~ /\S/;
        my ( $tag_start, $tag_end, $before ) = ( '', '', '' );

        if ( defined( my $level = $UL_STYLES{$style} ) )
        {             # registered list styles
            if ( $level > @LIST_STACK ) {
                my $tag;
                push @LIST_STACK, $tag = 'UL';
                if (SHOW_STYLE) {
                    $before = "<$tag>[$style]" . $N;
                } else {
                    $before = "<$tag>" . $N;
                }
                $tag_start = $tag_end = 'LI';
            } else {
                $level = @LIST_STACK - $level;
                while ( $level-- > 0 ) {
                    $before .= '</' . pop(@LIST_STACK) . '>' . $N;
                }
                $tag_start = $tag_end = 'LI';
            }
        } else {
        }

        if ( $tag_start eq '' ) {    # end of list
            while (@LIST_STACK) {
                $before .= '</' . pop(@LIST_STACK) . '>' . $N;
            }
            $tag_start = $tag_end = $STYLES{$style} || do {
                if (SHOW_STYLE_NOT_PROCESSED) {
                    use vars qw/%style_not_processed/;
                    # todo: add count
                    unless ( exists $style_not_processed{$style} ) {
                        print STDERR "style not defined '$style'\n"
                            if SHOW_STYLE_NOT_PROCESSED;
                        $style_not_processed{$style} = '';
                    }
                }
                $STYLES{'par'};
            };
            foreach (qw(qj qc ql qr)) {    # for some html elements...
                if ( $par_props{$_} ) {
                    $tag_start .= " ALIGN=$PAR_ALIGN{$_}";
                }
            }
        }

        $_[SELF]->trace("$tag_start-$tag_end: $text") if TRACE;
        my $char_props = $_[SELF]->force_char_props('end');
        if (SHOW_RTF_LINE_NUMBER) {
            output "$N$before<$tag_start>[$.]$text$char_props</$tag_end>$N";
        } else {
            output "$N$before<$tag_start>$text$char_props</$tag_end>$N";
        }
        $START_NEW_PARA = 1;
    },
    # Hypertextuel links
    #   'bookmark' => sub {
    #     $_[SELF]->trace("bookmark $event $text") if TRACE;
    #     if ($event eq 'end') {
    #       return if $in_Bookmark--;
    #       output("</a>");
    #     } else {
    #       return if ++$in_Bookmark;
    #       output("<a name='$text'>");
    #     }
    #   },
    #   'field' => sub {
    #     my $id = $_[0];
    #     $_[SELF]->trace("field $event $text") if TRACE;
    #     if ($event eq 'end') {
    #       return if $in_Field--;
    #       output("$text</a>");
    #     } else {
    #       return if ++$in_Field;
    #       output("<a href='#$id'>"); # doesn't work!
    #     }
    #   },
    # CHAR properties
    b      => $make_tag_handler->('b'),
    i      => $make_tag_handler->('i'),
    ul     => $make_tag_handler->('u'),
    sub    => $make_tag_handler->('sub'),
    super  => $make_tag_handler->('sup'),
    strike => $make_tag_handler->('strike'),
);

###############################################################################
# If you have an &<entity>; in your RTF document and if
# <entity> is a character entity, you'll see "&<entity>;" in the RTF document
# and the corresponding glyphe in the HTML document
# How to give a new definition to a control registered in %do_on_control:
# - method redefinition (could be the purist's solution)
# - $Control::do_on_control{control_word} = sub {};
# - when %do_on_control is exported write:
$do_on_control{'ansi'} =    # callback redefinition
    sub {
    # RTF: \'<hex value>
    # HTML: &#<dec value>;

    my @charmap_data = $_[SELF]->charmap_reader( $_[CONTROL] );

    my %charset = (    # general rule
        %charmap_defaults,
        # and some specific defs
        map( {  s/^\s+//;
                    split /\s+/
        } @charmap_data ) );
    *char = sub {
        my $char_props;
        if ($START_NEW_PARA) {
            $char_props     = $_[SELF]->force_char_props('start');
            $START_NEW_PARA = 0;
        } else {
            $char_props = $_[SELF]->process_char_props();
        }
        output $char_props . $charset{ $_[1] };
        }
    };

# symbol processing
# RTF: \~
# named chars
# RTF: \ldblquote, \rdblquote
$symbol{'~'}   = '&nbsp;';
$symbol{'tab'} = ' ';       #'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
$symbol{'ldblquote'} = '&laquo;';
$symbol{'rdblquote'} = '&raquo;';
$symbol{'line'}      = '<br>';

sub symbol {

    debug( 'symbol', @_ ) if RTF_DEBUG > 5;

    my $char_props;
    if ($START_NEW_PARA) {
        $char_props     = $_[SELF]->force_char_props('start');
        $START_NEW_PARA = 0;
    } else {
        $char_props = $_[SELF]->process_char_props();
    }
    if ( defined( my $sym = $symbol{ $_[1] } ) ) {
        output $char_props . $sym;
    } else {
        output $char_props . $_[1];    # as it
    }
}
# Text
# certainly do the same thing with the char() method
sub text {    # parser callback redefinition

    debug( 'text', @_ ) if RTF_DEBUG > 5;

    my $text       = $_[1];
    my $char_props = '';
    if ($START_NEW_PARA) {
        $char_props     = $_[SELF]->force_char_props('start');
        $START_NEW_PARA = 0;
    } else {
        $char_props = $_[SELF]->process_char_props();
    }
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    if ( defined $char_props ) {
        output("$char_props$text");
    } else {
        output("$text");
    }
}

sub debug {

    my $function = shift;

    print STDERR "[RTF::HTML::Converter::$function]" . ( join '|', @_ ), "\n";

}

1;
__END__
