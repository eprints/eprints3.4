package RTF::TEXT::Converter;
$RTF::TEXT::Converter::VERSION = '1.12';
use strict;
use warnings;

use RTF::Control;
use RTF::TEXT::Converter::ansi;
use RTF::TEXT::Converter::charmap;

@RTF::TEXT::Converter::ISA = qw(RTF::Control);

use constant TRACE                => 0;
use constant LIST_TRACE           => 0;
use constant SHOW_RTF_LINE_NUMBER => 0;

=head1 NAME

RTF::TEXT::Converter - Perl extension for converting RTF into text

=head1 VERSION

version 1.12

=head1 DESCRIPTION

Perl extension for converting RTF into text

=head1 SYNOPSIS

	use strict;
	use RTF::TEXT::Converter;

	my $object = RTF::TEXT::Converter->new(

		output => \*STDOUT

	);

	$object->parse_stream( \*RTF_FILE );

OR

	use strict;
	use RTF::TEXT::Converter;

	my $object = RTF::TEXT::Converter->new(

		output => \$string

	);

	$object->parse_string( $rtf_data );

=head1 METHODS

=head2 new()

Constructor method. Currently takes one named parameter, C<output>,
which can either be a reference to a filehandle, or a reference to
a string. This is where our text output will end up.

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

###########################################################################
my $N = "\n";    # Pretty-printing

my %charmap_defaults = map( { sprintf( "%02x", $_ ) => chr($_) } ( 0 .. 255 ) );

# you can split on sentences here if you want!!!
# some output parameters
%do_on_event = (
    'document' => sub {    # Special action
    },
    # Table processing
    'table' => sub {       # end of table
        if ( $event eq 'end' ) {
        } else {
        }
    },
    'row' => sub {         # end of row
        if ( $event eq 'end' ) {
            output "$text$N";
        } else {
            # not defined
        }
    },
    'cell' => sub {        # end of cell
        if ( $event eq 'end' ) {
            output "$text$N";
        } else {
            # not defined
        }
    },
    'par' => sub {         # Default rule: if no entry for a paragraph style
                           # Paragraph styles
                           #return output($text) unless $text =~ /\S/;
        output "$text$N";
    }, );

###############################################################################
# If you have an &<entity>; in your RTF document and if
# <entity> is a character entity, you'll see "&<entity>;" in the RTF document
# and the corresponding glyphe in the HTML document
# How to give a new definition to a control registered in %do_on_control:
# - method redefinition (could be the purist's solution)
# - $Control::do_on_control{control_word} = sub {};
# - when %do_on_control is exported write:

# OK, so a little rewrite has gone on here. I don't like opening 'ansi'
# and 'char_map' files, so I've wrapped them in RTF::TEXT::ansi.pm, and
# so on. This makes it an awful lot cleaner, but falls back as
# appropriate

$do_on_control{'ansi'} =    # callcack redefinition
    sub {

    my @charmap_data = $_[SELF]->charmap_reader( $_[CONTROL] );

    # Create the charset hash...
    my %charset = (

        # Defaults...
        %charmap_defaults,

        # Specifics from our charset file...
        map( {  s/^\s+//;
                    split /\s+/
            } @charmap_data )

    );

    # Over-ride &char to return our character mapping
    {
        no warnings 'redefine';
        *char = sub {
            output $charset{ $_[1] };
        }
    }

    };

# symbol processing
# RTF: \~
# named chars
# RTF: \ldblquote, \rdblquote
$symbol{'~'}         = ' ';
$symbol{'tab'}       = "\t";
$symbol{'ldblquote'} = '"';
$symbol{'rdblquote'} = '"';
$symbol{'line'}      = "\n";
$symbol{'_'}         = '-';

# If we get called from a non-ansi document, then we've not redefined
# char() to something sensible, so we put a nice definition here...
sub char {

    output $charmap_defaults{ $_[1] }

}

sub symbol {
    if ( defined( my $sym = $symbol{ $_[1] } ) ) {
        output $sym;
    } else {
        output $_[1];    # as it
    }
}

1;
__END__
