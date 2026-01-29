package RTF::Parser;
$RTF::Parser::VERSION = '1.12';
use strict;
use warnings;

=head1 NAME

RTF::Parser - A DEPRECATED event-driven RTF Parser

=head1 VERSION

version 1.12

=head1 DESCRIPTION

A DEPRECATED event-driven RTF Parser

=head1 PUBLIC SERVICE ANNOUNCEMENT

B<DO NOT USE THIS MODULE UNLESS YOU HAVE NO ALTERNATIVE.
Need rtf2*? Google for pandoc.>

A very short history lesson...

C<1.07> of this module was released in 1999 by the original author,
Philippe Verdret. I took over the module around 2004 with high intentions. I
added almost all of the POD, all of the tests, and most of the comments, and
rejigged the whole thing to use L<RTF::Tokenizer> for tokenizing the incoming
RTF, which fixed a whole class of problems.

The big problem is really that the whole module is an API which happens to have
C<rtf2html> and C<rtf2text> stuck on top of it. Any serious changes involve
breaking the API, and that seems the greater sin than telling people to go and
get themselves a better RTF convertor suite.

I had high hopes of overhauling the whole thing, but it didn't happen. I handed
over maintainership some years later, but no new version was forthcoming, and
the module has languished since then. There are many open bugs on rt.cpan.org
and in the reviews.

In a moment of weakness, I've picked up the module again with the aim of
adding this message, fixing one or two very minor bugs, and putting a version
that doesn't have B<UNAUTHORIZED RELEASE> in big red letters on the CPAN.

I doubt I'll ever tackle the bigger bugs (Unicode support), but I will accept
patches I can understand.

=head1 IMPORTANT HINTS

RTF parsing is non-trivial. The inner workings of these modules are somewhat
scary. You should go and read the 'Introduction' document included with this
distribution before going any further - it explains how this distribution fits
together, and is B<vital> reading.

If you just want to convert RTF to HTML or text, from inside your own script,
jump straight to the docs for L<RTF::HTML::Converter> or L<RTF::TEXT::Converter>
respectively.

=head1 SUBCLASSING RTF::PARSER

When you subclass RTF::Parser, you'll want to do two things. You'll firstly
want to overwrite the methods below described as the API. This describes what
we do when we have tokens that aren't control words (except 'symbols' - see below).

Then you'll want to create a hash that maps control words to code references
that you want executed. They'll get passed a copy of the RTF::Parser object,
the name of the control word (say, 'b'), any arguments passed with the control
word, and then 'start'.

=head2 An example...

The following code removes bold tags from RTF documents, and then spits back
out RTF.

  {

    # Create our subclass

      package UnboldRTF;

    # We'll be doing lots of printing without newlines, so don't buffer output

      $|++;

    # Subclassing magic...

      use RTF::Parser;
      @UnboldRTF::ISA = ( 'RTF::Parser' );

    # Redefine the API nicely

      sub parse_start { print STDERR "Starting...\n"; }
      sub group_start { print '{' }
      sub group_end   { print '}' }
      sub text        { print "\n" . $_[1] }
      sub char        { print "\\\'$_[1]" }
      sub symbol      { print "\\$_[1]" }
      sub parse_end   { print STDERR "All done...\n"; }

  }

  my %do_on_control = (

	# What to do when we see any control we don't have
	#   a specific action for... In this case, we print it.

    '__DEFAULT__' => sub {

      my ( $self, $type, $arg ) = @_;
      $arg = "\n" unless defined $arg;
      print "\\$type$arg";

     },

   # When we come across a bold tag, we just ignore it.

     'b' => sub {},

  );

  # Grab STDIN...

    my $data = join '', (<>);

  # Create an instance of the class we created above

    my $parser = UnboldRTF->new();

  # Prime the object with our control handlers...

    $parser->control_definition( \%do_on_control );

  # Don't skip undefined destinations...

    $parser->dont_skip_destinations(1);

  # Start the parsing!

    $parser->parse_string( $data );

=head1 METHODS

=cut


use vars qw($VERSION);

use Carp;
use RTF::Tokenizer 1.01;
use RTF::Config;

my $DEBUG = 0;

# Debugging stuff I'm leaving in in case someone is using it..,
use constant PARSER_TRACE => 0;

sub backtrace {
    Carp::confess;
}

$SIG{'INT'} = \&backtrace if PARSER_TRACE;
$SIG{__DIE__} = \&backtrace if PARSER_TRACE;

=head2 new

Creates a new RTF::Parser object. Doesn't accept any arguments.

=cut

sub new {

    # Get the real class name
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{_RTF_CONTROL_USED}++ if $INC{'RTF/Control.pm'};

    $self->{_DONT_SKIP_DESTINATIONS} = 0;

    bless $self, $class;

    return $self;

}

# For backwards compatability, we import RTF::Control's %do_on_control
# if we've loaded RTF::Control (which would suggest we're being subclassed
# by RTF::Control). This isn't nice or pretty, but it doesn't break things.
# I'd do this in new() but there's no guarentee it'll be set by then...

sub _install_do_on_control {

    my $self = shift;

    return if $self->{_DO_ON_CONTROL};

    if ( $self->{_RTF_CONTROL_USED} ) {

        $self->{_DO_ON_CONTROL} = \%RTF::Control::do_on_control;

    } else {

        $self->{_DO_ON_CONTROL} = {};

    }

}

=head2 parse_stream( \*FH )

This function used to accept a second parameter - a function specifying how
the filehandle should be read. This is deprecated, because I could find no
examples of people using it, nor could I see why people might want to use it.

Pass this function a reference to a filehandle (or, now, a filename! yay) to
begin reading and processing.

=cut

sub parse_stream {

    my $self   = shift;
    my $stream = shift;
    my $reader = shift;

    $self->_install_do_on_control();

    die("parse_stream no longer accepts a reader") if $reader;

    # Put an appropriately primed RTF::Tokenizer object into our object
    $self->{_TOKENIZER} = RTF::Tokenizer->new( file => $stream );

    $self->_parse();

    return $self;

}

=head2 parse_string( $string )

Pass this function a string to begin reading and processing.

=cut

sub parse_string {

    my $self   = shift;
    my $string = shift;

    $self->_install_do_on_control();

    # Put an appropriately primed RTF::Tokenizer object into our object
    $self->{_TOKENIZER} = RTF::Tokenizer->new( string => $string );

    $self->_parse();

    return $self;

}

=head2 control_definition

The code that's executed when we trigger a control event is kept
in a hash. We're holding this somewhere in our object. Earlier
versions would make the assumption we're being subclassed by
RTF::Control, which isn't something I want to assume. If you are
using RTF::Control, you don't need to worry about this, because
we're grabbing %RTF::Control::do_on_control, and using that.

Otherwise, you pass this method a reference to a hash where the keys
are control words, and the values are coderefs that you want executed.
This sets all the callbacks... The arguments passed to your coderefs
are: $self, control word itself (like, say, 'par'), any parameter the
control word had, and then 'start'.

If you don't pass it a reference, you get back the reference of the
current control hash we're holding.

=cut

sub control_definition {

    my $self = shift;

    if (@_) {

        if ( ref $_[0] eq 'HASH' ) {

            $self->{_DO_ON_CONTROL} = shift;

        } else {

            die "argument of control_definition() method must be an HASHREF";

        }

    } else {

        return $self->{_DO_ON_CONTROL};

    }

}

=head2 rtf_control_emulation

If you pass it a boolean argument, it'll set whether or not it thinks RTF::Control
has been loaded. If you don't pass it an argument, it'll return what it thinks...

=cut

sub rtf_control_emulation {

    my $self = shift;
    my $bool = shift;

    if ( defined $bool ) {

        $self->{_RTF_CONTROL_USED} = $bool;

    } else {

        return $self->{_RTF_CONTROL_USED};

    }

}

=head2 dont_skip_destinations

The RTF spec says that we skip any destinations that we don't have an explicit
handler for. You could well not want this. Accepts a boolean argument, true
to process destinations, 0 to skip the ones we don't understand.

=cut

sub dont_skip_destinations {

    my $self = shift;
    my $bool = shift;

    $self->{_DONT_SKIP_DESTINATIONS} = $bool;

}

# This is how he decided to call control actions. Leaving
#   it to do the right thing at the moment... Users of the
#	module don't need to know our dirty little secret...

{

    package RTF::Action;
$RTF::Action::VERSION = '1.12';
use RTF::Config;

    use vars qw($AUTOLOAD);

    my $default;

    # The original RTF::Parser allowed $LOGFILE to be set
    # that made RTF::Config do fun things. We're allowing it
    # to, but wrapping it up a bit more carefully...
    if ($LOG_FILE) {

        $default = sub { $RTF::Control::not_processed{ $_[1] }++ }

    }

    my $sub;

    sub AUTOLOAD {

        my $self = $_[0];

        $AUTOLOAD =~ s/^.*:://;

        no strict 'refs';

        if ( defined( $sub = $self->{_DO_ON_CONTROL}->{$AUTOLOAD} ) ) {

            # Yuck, empty if. But we're just going to leave it for a while

        } else {

            if ($default) {

                $sub = $default

            } elsif ( $self->{_DO_ON_CONTROL}->{'__DEFAULT__'} ) {

                $sub = $self->{_DO_ON_CONTROL}->{'__DEFAULT__'};

            } else {

                $sub = sub { };

            }

        }

        # I don't understand why he's using goto here...
        *$AUTOLOAD = $sub;
        goto &$sub;

    }

}

=head1 API

These are some methods that you're going to want to over-ride if you
subclass this modules. In general though, people seem to want to subclass
RTF::Control, which subclasses this module.

=head2 parse_start

Called before we start parsing...

=head2 parse_end

Called when we're finished parsing

=head2 group_start

Called when we encounter an opening {

=head2 group_end

Called when we encounter a closing }

=head2 text

Called when we encounter plain-text. Is given the text as its
first argument

=head2 char

Called when we encounter a hex-escaped character. The hex characters
are passed as the first argument.

=head2 symbol

Called when we come across a control character. This is interesting, because,
I'd have treated these as control words, so, I'm using Philippe's list as control
words that'll trigger this for you. These are C<-_~:|{}*'\>. This needs to be
tested.

=head2 bitmap

Called when we come across a command that's talking about a linked bitmap
file. You're given the file name.

=head2 binary

Called when we have binary data. You get passed it.

=cut

sub parse_start { }
sub parse_end   { }
sub group_start { }
sub group_end   { }
sub text        { }
sub char        { }
sub symbol      { }    # -_~:|{}*'\
sub bitmap      { }    # \{bm(?:[clr]|cwd)
sub binary      { }

# This is the big, bad parse routine that isn't called directly.
# We loop around RTF::Tokenizer, making event calls when we need to.

sub _parse {

    # Read in our object
    my $self = shift;

    # Execute any pre-parse subroutines
    $self->parse_start();

    # Loop until we find the EOF
    while (1) {

        # Read in our initial token
        my ( $token_type, $token_argument, $token_parameter ) =
            $self->{_TOKENIZER}->get_token();

        # Control words
        if ( $token_type eq 'control' ) {

            # We have a special handler for control words
            $self->_control( $token_argument, $token_parameter );

            # Plain text
        } elsif ( $token_type eq 'text' ) {

            # Send it to the text() routine
            $self->text($token_argument);

            # Groups
        } elsif ( $token_type eq 'group' ) {

            # Call the appropriate handler
            $token_argument ? $self->group_start :
                $self->group_end;

            # EOF
        } else {

            last;

        }

    }

    # All done
    $self->parse_end();
    $self;

}

# Control word handler (yeuch)
#	purl, be RTF barbie is <reply>Control words are *HARD*!
sub _control {

    my $self = shift;
    my $type = shift;
    my $arg  = shift;

    #  standard, control_symbols, hex

    # Funky destination
    if ( $type eq '*' ) {

        # We might actually want to process it...
        if ( $self->{_DONT_SKIP_DESTINATIONS} ) {

            $self->_control_execute('*');

        } else {

            # Grab the next token
            my ( $token_type, $token_argument, $token_parameter ) =
                $self->{_TOKENIZER}->get_token();

            # Basic sanity check
            croak('Malformed RTF - \* not followed by a control...')
                unless $token_type eq 'control';

            # Do we have a handler for it?
            if ( defined $self->{_DO_ON_CONTROL}->{$token_argument} ) {
                $self->_control_execute( $token_argument, $token_parameter );
            } else {
                $self->_skip_group();
                $self->group_end();
            }
        }

        # Binary data
    } elsif ( $type eq 'bin' ) {

        # Grab the next token
        my ( $token_type, $token_argument, $token_parameter ) =
            $self->{_TOKENIZER}->get_token();

        # Basic sanity check
        croak('Malformed RTF - \bin not followed by text...')
            unless $token_type eq 'text';

        # Send it to the handler
        $self->binary($token_argument);

        # Implement a bitmap handler here

        # Control symbols
    } elsif ( $type =~ m/[-_~:|{}*\\]/ ) {

        # Send it to the handler
        $self->symbol($type);

        # Entity
    } elsif ( $type eq "'" ) {

        # Entity handler
        $self->char($arg);

        # Some other control type - give it to the control executer
    } else {

        # Pass it to our default executer
        $self->_control_execute( $type, $arg )

    }

}

# Control word executer (this is nasty)
sub _control_execute {

    my $self = shift;
    my $type = shift;
    my $arg  = shift;

    no strict 'refs';
    &{"RTF::Action::$type"}( $self, $type, $arg, 'start' );

}

# Skip a group
sub _skip_group {

    my $self = shift;

    my $level_counter = 1;

    while ($level_counter) {

        # Get a token
        my ( $token_type, $token_argument, $token_parameter ) =
            $self->{_TOKENIZER}->get_token();

        # Make sure we can't loop forever
        last if $token_type eq 'eof';

        # We're in business if it's a group
        if ( $token_type eq 'group' ) {

            $token_argument ? $level_counter++ :
                $level_counter--;

        }

    }

}

1;

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>, originally by Philippe Verdret

=head1 COPYRIGHT

Copyright 2004 B<Pete Sergeant>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CREDITS

This work was carried out under a grant generously provided by The Perl Foundation -
give them money!
