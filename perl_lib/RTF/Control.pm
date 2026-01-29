package RTF::Control;
$RTF::Control::VERSION = '1.12';
use strict;
use warnings;

# Sonovision-Itep, Philippe Verdret 1998-1999
# TPF - Pete Sergeant 2003 - 2004

=head1 NAME

RTF::Control - Application of RTF::Parser for document conversion

=head1 VERSION

version 1.12

=head1 DESCRIPTION

Application of RTF::Parser for document conversion

=head1 OVERVIEW

L<RTF::Control> is a sublass of L<RTF::Parser>. L<RTF::Control> can be seen as
a helper module for people wanting to write their own document convertors -
L<RTF::HTML::Convertor> and L<RTF::TEXT::Convertor> both subclass it.

I am the new maintainer of this module. My aim is to keep the interface
identical to the old interface while cleaning up, documenting, and testing
the internals. There are things in the interface I'm unhappy with, and things
I like - however, I'm maintaining rather than developing the module, so, the
interface is mostly frozen.

=head1 HOW IT ALL WORKS

For starters, go and look at the source of M<RTF::TEXT::Convertor>


Except for B<RTF::Parser subs>, the following is a list of variables
exported by RTF::Control that you're expected to tinker with in your
own subclass.

=head2 RTF::Parser subs

If you read the docs of RTF::Parser you'll see that you can redefine some
subs there - RTF::Control has its own definitions for all of these, but you
might want to over-ride C<symbol()>, C<text()>, and C<char()>. We'll look
at what the defaults of each of these do, and what you need to do if you
want to override any of them a little further down.

=head2 %symbol

This hash is actually merged into %do_on_control, with the value wrapped in
a subroutine that effectively says C<print shift>. You can put any control
words that should map directly to a certain output in here - C<\tab>, for
example could be C<$symbol{'tab'} = "\t">.

=head2 %info

This hash gets filled with document meta-data, as per the RTF specification.

=head2 %par_props

Not really sure, but paragraph properties

=head2 %do_on_event %do_on_control

%do_on_control tells us what to do when we meet a specific control word.
The values are coderefs. %do_on_event also holds coderefs, but these are
more abstract things to do, say when the stylesheet changes. %do_on_event
thingies tend to be called by %do_on_control thingies, as far as I can tell.

=head2 $style $newstyle

Style is the current style, $newstyle is the one we're about to
change to if we're about to change...

=head2 $event

Current event

=head2 $text

Pending text

=cut

# Define all our dependencies and other fluff

use RTF::Parser;
use RTF::Config;
use RTF::Charsets;    # define names of chars

use File::Basename;
use Exporter;

# I'm an RTF::Parser! I'm an Exporter! I'm a class!
# "When I grow up, I'm going to bovine university!"

@RTF::Control::ISA = qw(Exporter RTF::Parser);

# Define the symbols we'll be exporting - these are
# documented in the API part of the POD and a little
# further down

use vars qw(

    %symbol %info %par_props %do_on_event %do_on_control
    $style $newstyle $event $text

);

# There are used to that we have named arguments for callbacks
# I don't like this, but hey, I didn't design it, and I'm meant
# to be maintaining the interface :-)

use constant SELF    => 0;     # rtf processor instance
use constant CONTROL => 1;     # control word
use constant ARG     => 2;     # associated argument
use constant EVENT   => 3;     # start/end event
use constant TOP     => -1;    # access to the TOP element of a stack

# Actually export stuff...

@RTF::Control::EXPORT = qw(

    output

    %symbol
    %info
    %do_on_event
    %do_on_control
    %par_props

    $style
    $newstyle
    $event
    $text

    SELF
    CONTROL
    ARG
    EVENT
    TOP

);

# Flags to specify where we are... Because this is all undocumented
# I feel justified putting these into a hash at some point in the
# near future... They also shouldn't be package variables, they
# should be class variables, but, to be honest, trying to rid this
# module of package variables seems an exercise in futility if I'm
# actually trying to maintain the interface... I could internalise
# everything that isn't part of the API though

my $IN_STYLESHEET = 0;    # inside or outside style table
my $IN_FONTTBL    = 0;    # inside or outside font table
my $IN_TABLE      = 0;

# Declare where we're going to be holding meta-data etc
my %fonttbl;
my %stylesheet;
my %colortbl;

# Property stacks
my @par_props_stack  = (); # stack of paragraph properties
my @char_props_stack = (); # stack of character properties
my @control          = (); # stack of control instructions, rename control_stack

# Some other stuff
my $stylename  = '';
my $cstylename = '';       # previous encountered style
my $cli        = 0;        # current line indent value
my $styledef   = '';

=head2 new

Returns an RTF::Control object. RTF::Control is a subclass of RTF::Parser.
Internally, we call RTF::Parser's new() method, and then we call an internal
method called _configure(), which takes care of options we were passed.

ADD STUFF ON -output AND -confdir

=cut

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    $self->_configure(@_);

    return $self;

}

# This is a private method. It accepts a hash (well, a list)
#      of values, and stores them. If one of them is 'output',
#      it calls a function I'm yet to examine. This was done
#      in a horrendous way - it's now a lot tidier. :-)

sub _configure {

    my $self = shift;

    my %options = @_;

    # Sanitize the options
    my %clean_options;
    for my $key ( keys %options ) {

        my $oldkey = $key;

        $key =~ s/^-//;
        $key = lc($key);

        $clean_options{$key} = $options{$oldkey}

    }

    $self->{'_RTF_Control_Options'} = \%clean_options;

    $self->set_top_output_to( $clean_options{'output'} )
        if $clean_options{'output'};

    return $self;

}

use constant APPLICATION_DIR => 0;

=head2 application_dir

I'm leaving this method in because removing it will cause a backward-compatability
nightmare. This method returns the ( wait for it ) path that the .pm file corresponding
to the class that the object is contained, without a trailing semi-colon. Obviously
this is nasty in several ways. If you've set C<-confdir> in C<new()> that will be
returned instead. You should definitely take that route if you're on an OS on which
Perl can't use / as a directory seperator.

=cut

sub application_dir {

    # Grab our object
    my $self = shift;

    # Return -confdir if set
    return $self->{'_RTF_Control_Options'}->{'confdir'}
        if $self->{'_RTF_Control_Options'}->{'confdir'};

    # Grab the class name
    my $class = ref $self;

    # Clean it up and look it up in %INC
    $class =~ s|::|/|g;
    $class = $INC{"$class.pm"};

    return dirname $class;

}

=head2 charmap_reader

This nicely abstracts away using application_dir and so on. It's a method
call. It'll take the name of the class, and an argument for the module/file
it's looking for. This is likely to be 'ansi' or 'charmap'. This argument,
for historical reasons (ho ho ho) will have any _'s removed in the check for
a module name ... C< $self->charmap_reader('char_map') > will thus look for, for
example, C< RTF::TEXT::charmap > to load. It'll return the data in the file as
an array of lines. This description sucks.

=cut

sub charmap_reader {

    my $self = shift;
    my $file = shift;

    my @char_map_data;

    # Try and work out what our character set module would be called...
    my $module_file = $file;
    $module_file =~ s/_//g;
    my $module_name = ref($self) . '::' . $module_file;

    # Can we load it?
    eval "use $module_name";

    # That would be a no...
    if ($@) {

        # Create a path for the charset file using the old method...
        my $charset_file = $_[SELF]->application_dir(__FILE__) . "/$file";

        # Try and open it...
        open( CHAR_MAP, "< $charset_file" ) or
            die "Unable to open the charset file '$charset_file': $!";

        # Read in the data...
        @char_map_data = (<CHAR_MAP>);

        # Why yes, yes we can...
    } else {

        my $sub_name = $module_name . '::' . 'data';
        @char_map_data = main->$sub_name();

    }

    return @char_map_data;

}

###########################################################################

# This stuff is all to do with the stack, and I'm not really sure how it
#   works. I'm hoping it'll become more obvious as I go. The routines themselves
#   are now all documented, but who knows what the stack is or why? hrm?

# This hurts my little brane.

# Holds the output stack
my @output_stack;

# Defines how large the output stack can be
use constant MAX_OUTPUT_STACK_SIZE => 0;  # PV: 8 seems a good value
                                          # PS: Then why not default it to that?

=head1 Stack manipulation

=head2 dump_stack

Serializes and prints the stack to STDERR

=cut

# Serializes the stack, and prints it to STDERR.
sub dump_stack {

    my $stack_size = @output_stack;

    print STDERR "Stack size: $stack_size\n";

    print STDERR $stack_size-- . " |$_|\n" for reverse @output_stack;

}

=head2 output

Holder routine for the current thing to do with output text we're given.
It starts off as the same as C<$string_output_sub>, which adds the string
to the element at the C<TOP> of the output stack. However, the idea, I
believe, is to allow that to be changed at will, using C<push_output>.

=cut

sub output {

    $output_stack[TOP] .= $_[0] if defined $_[0];

}

# I'm guessing (because I'm generous ;-) that this is done because
#   subclasses might want to modifiy the values of these. These are
#   obviously the two different ways to spit out ... something. We
#   start with the string_output_sub being what &output does tho.

my $nul_output_sub = sub {
    #print STDERR "** $_[0] **\n";
};

my $string_output_sub = sub {

    $output_stack[TOP] .= $_[0] if $_[0];

};

=head2 push_output

Adds a blank element to the end of the stack. It will change (or
maintain) the function of C<output> to be C<$string_output_sub>,
unless you pass it the argument C< 'nul' >, in which case it will
set C<output> to be C<$nul_output_sub>.

=cut

sub push_output {

    # If we've set a maximum output stack and then exceeded it, complain.
    if (MAX_OUTPUT_STACK_SIZE) {
        die "max size of output stack exceeded"
            if @output_stack == MAX_OUTPUT_STACK_SIZE;
    }

    # If we didn't get an argument, output becomes string...
    unless ( defined( $_[0] ) ) {

        no warnings 'redefine';
        *output = $string_output_sub;

        # If we were given 'nul', set output to $nul_output_sub
    } elsif ( $_[0] eq 'nul' ) {

        no warnings 'redefine';
        *output = $nul_output_sub;

    }

    # Add an empty element to the end of the ouput stack
    push @output_stack, '';

}

=head2 pop_output

Removes and returns the last element of the ouput stack

=cut

# Remove and return an element of the output stack, which
# should basically be the in-scope text... See how &do_on_info
# uses this

sub pop_output {

    pop @output_stack;

}

use constant SET_TOP_OUTPUT_TO_TRACE => 0;

=head2 set_top_output_to

Only called at init time, is a method call not a function.
Sets the action of C<flush_top_output>, depending on whether
you pass it a filehandle or string reference.

=cut

# Sets flush_top_output to print to the appropriate thingy
sub set_top_output_to {

    my $self = shift;

    # Are we being passed a filehandle?

    local *X = $_[0];

    if ( fileno X ) {

        my $stream = *X;

        # Debugging info if asked for
        print STDERR "stream: ", fileno X, "\n" if SET_TOP_OUTPUT_TO_TRACE;

        # Turn off warnings
        no warnings 'redefine';

        # Overwrite &flush_top_output
        *flush_top_output = sub {
            print $stream $output_stack[TOP];
            $output_stack[TOP] = '';
        };

        # We've been passed a reference to a scalar...

    } elsif ( ref $_[0] eq 'SCALAR' ) {

        print STDERR "output to string\n" if SET_TOP_OUTPUT_TO_TRACE;

        my $content_ref = $_[0];

        no warnings 'redefine';

        *flush_top_output = sub {
            $$content_ref .= $output_stack[TOP];
            $output_stack[TOP] = '';
        };

        # Someone's done something weird

    } else {

        warn "unknown output specification: $_[0]\n";

    }

}

# the default prints on the selected output filehandle

=head2 flush_top_output

Output the top element of the stack in the way specified by the call
to C<set_top_output_to>

=cut

sub flush_top_output {

    print $output_stack[TOP];
    $output_stack[TOP] = '';

}

###########################################################################
# Trace management
use constant RTF_DEBUG   => 0;
use constant TRACE       => 0;
use constant STACK_TRACE => 0;    #
use constant STYLESHEET_TRACE =>
    0;    # If you want to see the stylesheet of the document
use constant STYLE_TRACE => 0;    #
use constant LIST_TRACE  => 0;

$| = 1 if TRACE or STACK_TRACE or RTF_DEBUG;

# Debugging function - prints the number of _'s matching
# the number of controls in our current control stack,
# and anything else we were passed, and the $. - input
# line number.

sub trace {
    #my(@caller) = (caller(1));
    #my $sub = (@caller)[3];
    #$sub =~ s/.*:://;
    #$sub = sprintf "%-12s", $sub;
    shift if ref $_[0];
    print STDERR "[$.]", ( '_' x $#control . "@_\n" );
}
$SIG{__DIE__} = sub {
    require Carp;
    Carp::confess;
    }
    if RTF_DEBUG;

###########################################################################
# Some generic routines
use constant DISCARD_CONTENT => 0;

# This seems to be what we do when we hit a control word
#   we're not going to parse. He seems to be manually
#   implementing this some times - I wonder why?

sub discard_content {

    # Read in information about the control word we hit
    my ( $control, $arg, $cevent ) = ( $_[CONTROL], $_[ARG], $_[EVENT] );

    trace "($_[CONTROL], $_[ARG], $_[EVENT])" if DISCARD_CONTENT;

    # This I don't understand. Presumably if we've hit 0, then it's
    # the close of a part of the document being dictated by a char
    # property, like, say, \b1I'm bold\b0 I'm not.

    if ( defined $arg && $_[ARG] eq "0" ) {

        # Remove the last element on the output stack
        pop_output();

        # Set the property as on(?) on the control stack
        # This should probably be a 0. Something to test
        # later.
        $control[TOP]->{"$_[CONTROL]1"} = 1;

        # Add a blank element to the end of the output stack
    } elsif ( $_[EVENT] eq 'start' ) {

        push_output();
        $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

    } elsif ( defined $arg && $_[ARG] eq "1" ) {
        $cevent = 'start';
        push_output();

    } elsif ( $_[EVENT] eq 'end' ) {    # End of discard

        my $string = pop_output();

        if ( length $string > 30 ) {
            $string =~ s/(.{1,10}).*(.{1,10})/$1 ... $2/;
        }

        trace "discard content of \\$control: $string" if DISCARD_CONTENT;

    } else {

        die "($_[CONTROL], $_[ARG], $_[EVENT])" if DISCARD_CONTENT;

    }

}

# Document meta-data collator. Whenever we hit an info group,
# this sub is called. All it does is put all the text 'in-scope'
# into the %info hash...

sub do_on_info {

    my $string;
    my $arg = $_[ARG] || '';

    if ( $_[EVENT] eq 'start' ) {

        push_output();
        $control[TOP]->{"$_[CONTROL]$arg"} = 1;

    } else {

        $string = pop_output();
        $info{"$_[CONTROL]$arg"} = $string;

    }
}

# SYMBOLS
# default mapping for symbols
# char processed by the parser symbol() callback: - _ ~ : | { } * ' \\
%symbol = qw(
    | |
    _ _
    : :
    bullet *
    endash -
    emdash --
    ldblquote ``
    rdblquote ''
);
$symbol{rquote}   = "\'";
$symbol{lquote}   = "\`";
$symbol{'column'} = "\t";
$symbol{'tab'}    = "\t";
$symbol{'line'}   = "\n";
$symbol{'page'}   = "\f";

# Handler for symbols - prints the symbol corresponding
# to our first argument...

sub do_on_symbol {

    output $symbol{ $_[CONTROL] };

}

my %symbol_ctrl = map {    # install the do_on_symbol() routine
    if (/^[a-z]+$/) {
        $_ => \&do_on_symbol;
    } else {
        'undef' => undef;
    }
} keys %symbol;

###########################################################################################
my %char_props;    # control hash must be declarated before install_callback()
# purpose: associate callbacks to controls
# 1. an hash name that contains the controls
# 2. a callback name

# Sets the call back given as the second argument
# as the %do_on_control for all controls currently
# in %char_props. DON'T UNDERSTAND.

sub install_callback {    # not a method!!!

    my ( $control, $callback ) = ( $_[1], $_[2] );
    no strict 'refs';
    unless (%char_props) {    # why I can't write %{$control}
        die "'%$control' not defined";
    }
    for ( keys %char_props ) {
        $do_on_control{$_} = \&{$callback};
    }
}
# TOGGLES
# {\<toggle> ...}
# {\<toggle>0 ...}
###########################################################################
# How to give a general definition?
#my %control_definition = ( # control => [default_value nassociated_callback]
#             'char_props' => qw(0 do_on_control),
#            );

# Remove character formatting properties ... there are actually more
# character formatting properties defined in the RTF spec, but
# these seem to be the ones supported by this module...

sub reset_char_props {

    %char_props = map {

        $_ => 0

    } qw(b i ul sub super strike);
}

my $char_prop_change   = 0;
my %current_char_props = %char_props;
use constant OUTPUT_CHAR_PROPS => 0;

# Force a START or END event on our current character
# properties...  This is a method call.

sub force_char_props {    # force a START/END event

    # Obviously you're not allowed to do this in the fonttable
    # or style sheet...

    return if $IN_STYLESHEET or $IN_FONTTBL;

    trace "@_" if OUTPUT_CHAR_PROPS;

    # [0] is our object
    $event = $_[1];    # END or START
                       # close or open all activated char prorperties

    push_output();

    while ( my ( $char_prop, $value ) = each %char_props ) {

        next unless $value;

        trace "$event active char props: $char_prop" if OUTPUT_CHAR_PROPS;

        if ( defined( my $action = $do_on_event{$char_prop} ) ) {

            ( $style, $event ) = ( $char_prop, $event );

            &$action;

        }

        $current_char_props{$char_prop} = $value;

    }

    $char_prop_change = 0;

    pop_output();

}

use constant PROCESS_CHAR_PROPS => 0;

# Only run outside of stylesheets and fonttables,
# and only when the $char_prop_change flag is
# set.

sub process_char_props {

    return if $IN_STYLESHEET or $IN_FONTTBL;

    return unless $char_prop_change;

    # Add a new output block

    push_output();

    # Go through char_props (is the what we were, or what we're going to?!)
    while ( my ( $char_prop, $value ) = each %char_props ) {

        # Get the current character property
        my $prop = $current_char_props{$char_prop};

        # Set it to an explicit 0 if not set
        $prop = defined $prop ? $prop : 0;

        trace "$char_prop $value" if PROCESS_CHAR_PROPS;

        # If the values in %char_props and $current_char_props don't match..
        if ( $prop != $value ) {

            # See if we have an event...
            if ( defined( my $action = $do_on_event{$char_prop} ) ) {

                # Set event to start or end depending on if
                # the $value is a literal 1.
                $event = $value == 1 ? 'start' : 'end';

                ( $style, $event ) = ( $char_prop, $event );

                # Fire the event
                &$action;

            }

            # Set the $current_char_props to equal what was in %char_props
            $current_char_props{$char_prop} = $value;

        }

        trace "$char_prop - $prop - $value" if PROCESS_CHAR_PROPS;

    }

    # Reset the flag
    $char_prop_change = 0;

    # Return whatever was on the stack
    pop_output();

}

use constant DO_ON_CHAR_PROP => 0;

# Again, not called in a font or stylesheet, for obvious reasons.
# Set the char_prop_change flag. If the argument is '0', we set
# that character property to that - if the event is start, we set
# it to one, otherwise we throw a warning.

sub do_on_char_prop {    # associated callback

    return if $IN_STYLESHEET or $IN_FONTTBL;

    my ( $control, $arg, $cevent ) = ( $_[CONTROL], $_[ARG], $_[EVENT] );

    trace "my(\$control, \$arg, \$cevent) = ($_[CONTROL], $_[ARG], $_[EVENT]);"
        if DO_ON_CHAR_PROP;

    $char_prop_change = 1;

    if ( defined( $_[ARG] ) and $_[ARG] eq "0" ) {    # \b0

        $char_props{ $_[CONTROL] } = 0;

    } elsif ( $_[EVENT] eq 'start' ) {                # eg. \b or \b1

        $char_props{ $_[CONTROL] } = 1;

    } else {                                          # 'end'

        warn "statement not reachable";
        $char_props{ $_[CONTROL] } = 0;

    }

}

# LOOK MA! THIS BE IMPORTANT
__PACKAGE__->reset_char_props();
__PACKAGE__->install_callback( 'char_props', 'do_on_char_prop' );

###########################################################################
# not more used!!!
#use constant DO_ON_TOGGLE => 0;
#sub do_on_toggle {     # associated callback
##
#
# return if $IN_STYLESHEET or $IN_FONTTBL;
# my($control, $arg, $cevent) = ($_[CONTROL], $_[ARG], $_[EVENT]);
# trace "my(\$control, \$arg, \$cevent) = ($_[CONTROL], $_[ARG], $_[EVENT]);" if DO_ON_TOGGLE;
#
# if ($_[ARG] eq "0") {     # \b0, register an START event for this control
#   $control[TOP]->{"$_[CONTROL]1"} = 1; # register a start event for this properties
#   $cevent = 'end';
# } elsif ($_[EVENT] eq 'start') { # \b or \b1
#   $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;
# } else {          # $_[EVENT] eq 'end'
#   if ($_[ARG] eq "1") {
#     $cevent = 'start';
#   } else {
#   }
# }
# trace "(\$style, \$event, \$text) = ($control, $cevent, '')" if DO_ON_TOGGLE;
# if (defined (my $action = $do_on_event{$control})) {
#   ($style, $event, $text) = ($control, $cevent, '');
#   &$action;
# }
#}

###########################################################################
# FLAGS
use constant DO_ON_FLAG => 0;

# Simply sets that pargraph properties of said flag to 1

sub do_on_flag {

    #my($control, $arg, $cevent) = ($_[CONTROL], $_[ARG], $_[EVENT]);
    die if $_[ARG];                      # no argument by definition
    trace "$_[CONTROL]" if DO_ON_FLAG;
    $par_props{ $_[CONTROL] } = 1;

}

use vars qw/%charset/;
my $bullet_item = 'b7';    # will be redefined in a next release!!!

# Try to find a "RTF/<application>/char_map" file
# possible values for the control word are: ansi, mac, pc, pca
sub define_charset {

    my $charset = $_[CONTROL];
    eval {
        no strict 'refs';
        *charset = \%{"$charset"};
    };

    warn $@ if $@;

    my @charset_data = $_[SELF]->charmap_reader('char_map');

    my ( $name, $char, $hexa );
    my %char = map {

        s/^\s+//;
        next unless /\S/;
        ( $name, $char ) = split /\s+/;

        if ( !defined( $hexa = $charset{$name} ) ) {

            'undef' => undef;

        } else {

            $hexa => $char;

        }

    } (@charset_data);

    %charset = %char;    # for a direct translation of hexadecimal values
    warn $@ if $@;

}

my %flag_ctrl = (
    'ql' => \&do_on_flag,
    'qr' => \&do_on_flag,
    'qc' => \&do_on_flag,
    'qj' => \&do_on_flag,

    #
    'ansi' => \&define_charset,    # The default
    'mac'  => \&define_charset,    # Apple Macintosh
    'pc'   => \&define_charset,    # IBM PC code page 437
    'pca'  => \&define_charset,    # IBM PC code page 850
                                   #

    'pict' => \&discard_content,   #
    'xe'   => \&discard_content,   # index entry
                                   #'v'  => \&discard_content,  # hidden text
);

sub do_on_destination {
    trace "currently do nothing";
}
my %destination_ctrl = ();

sub do_on_value {
    trace "currently do nothing";
}
my %value_ctrl = ();

my %pn        = ();    # paragraph numbering
my $field_ref = '';    # identifier associated to a field
#trace "define callback for $_[CONTROL]";

# BEGIN API REDEFINITION

#   Ok, so this is actually the place to start as far as concerns
#     working out how the hell^Wfuck this thing works. I'm moving
#     all the constants to the top, and adding API documentation
#     here so future readers will have less trouble.

use constant GROUP_START_TRACE => 0;
use constant GROUP_END_TRACE   => 0;
use constant TEXT_TRACE        => 0;
use constant PARSE_START_END   => 0;

# Called when we first start actually parsing the document
sub parse_start {

    my $self = shift;

    # Place holders for non-printed data

    %info       = ();
    %fonttbl    = ();
    %colortbl   = ();
    %stylesheet = ();

    # Add an initial element to our output stack

    push_output();

    # If there's an event defined for the start of a document,
    #   execute it now...

    if ( defined( my $action = $do_on_event{'document'} ) ) {

        # $event tells our action handler what's happening...

        $event = 'start';

        # Actually execute said action

        &$action;

    }

    # Prints and clears the top element on the output stack

    flush_top_output();

    # Add another element to the output stack

    push_output();

}

# Called at the end of parsing
sub parse_end {

    my $self = shift;

    # @output_stack+0 forces scalar context?
    trace "parseEnd \@output_stack: ", @output_stack + 0 if STACK_TRACE;

    # Call the end of document even if it exists
    if ( defined( my $action = $do_on_event{'document'} ) ) {

        ( $style, $event, $text ) = ( $cstylename, 'end', '' );
        &$action;

    }

    # Print and clear the top element on the output stack

    flush_top_output();    # @output_stack == 2;

}

sub group_start {          # on {

    my $self = shift;

    trace "" if GROUP_START_TRACE;

    # Take a copy of the parent block's paragraph properties
    push @par_props_stack, {%par_props};

    # Take a copy of the parent block's character properties
    push @char_props_stack, {%char_props};

    # Aha! More accurately, controls we've opened, so we can close them in group_end()
    push @control, {};    # hash of controls

}

sub group_end {           # on }
                          # par properties

    # Retrieve parent block's paragraph properties
    %par_props = %{ pop @par_props_stack };

    # And use it to set the current stylename
    $cstylename = $par_props{'stylename'};    # the current style

    # Char properties
    # process control like \b0

    # Grab the character properties of our parent
    %char_props = %{ pop @char_props_stack };

    # Fire off the 'char props have changed' event
    $char_prop_change = 1;
    output process_char_props();

    # Always a /really/ /really/ bad sign :-(
    no strict qw/refs/;

    # Send an end thingy to each control we're closing
    foreach my $control ( keys %{ pop @control } ) {    # End Events!
        $control =~ /([^\d]+)(\d+)?/;                   # eg: b0, b1
        trace "($#control): $1-$2" if GROUP_END_TRACE;
        # sub associated to $1 is already defined in the "Action" package
        &{"RTF::Action::$1"}( $_[SELF], $1, $2, 'end' );
    }
}

# Just dump text
sub text {

    trace "$_[1]" if TEXT_TRACE;
    output( $_[1] );

}

# If we have an equiv, print it, otherwise, print the original

sub char {

    if ( defined( my $char = $charset{ $_[1] } ) ) {
        #print STDERR "$_[1] => $char\n";
        output "$char";
    } else {
        output "$_[1]";
    }
}

sub symbol {    # symbols: \ - _ ~ : | { } * \'

    if ( defined( my $sym = $symbol{ $_[1] } ) ) {
        output "$sym";
    } else {
        output "$_[1]";    # as it
    }
}

sub debug {

    my $function = shift;

    print STDERR "[RTF::Control::$function]" . ( join '|', @_ ), "\n";

}

%do_on_control = (
    %do_on_control,
    %flag_ctrl,
    %value_ctrl,
    %symbol_ctrl,
    %destination_ctrl,

    # Resets character formatting in scope... Note how we don't
    # check for start and end events? My guess is this is because
    # the original author is a BAD BAD MAN, and because running
    # reset_char_props() when \plain goes out of scope doesn't
    # cause any side effects. Something to experiment with when
    # I have a regression test suite...
    ###########################################################

    'plain' => sub {

        reset_char_props();

    },

    ###########################################################

    # The only thing puzzling me here is why we're doing a null
    # call to push_output. This (and other subroutines below)
    # are ripe for a bit of refactoring - they all do the same
    # thing!
    ###########################################################

    'rtf' => sub {    # rtfN, N is version number

        if ( $_[EVENT] eq 'start' ) {

            push_output('nul');
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            # There may actually be content at this point!
            flush_top_output();

            # The buffer should be empty at this point.
            # Make it so :-) This should use an RTF::Tokenizer
            # method before I release this as production.
            # TODO...

            $_[SELF]->{_TOKENIZER}->{_BUFFER}     = '';
            $_[SELF]->{_TOKENIZER}->{_FILEHANDLE} = '';

        }

    },

    ###########################################################

    # Info group. The &do_on_info sub is trivial, and merely puts
    # the rest of the text in a destination into %info, with the
    # key being the field (like 'title'). creatim is kinda clever
    # then in that it turns the rest of those fields into one
    # long text string.
    #
    # Other information we could grab:
    # {\printim\yr1997\mo11\dy3\hr11\min5}
    # {\version3}{\edmins1}{\nofpages3}{\nofwords1278}{\nofchars7287}
    # {\*\company SONOVISION-ITEP}{\vern57443}
    ###########################################################

    'info' => sub {    # {\info {...}}

        if ( $_[EVENT] eq 'start' ) {

            # Stops us collecting any text we don't want

            push_output('nul');
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            pop_output();

        }

    },

    'title'  => \&do_on_info,    # destination
    'author' => \&do_on_info,    # destination
    'revtim' => \&do_on_info,    # destination
    'creatim' =>
        \&do_on_info,    # destination, {\creatim\yr1996\mo9\dy18\hr9\min17}
    'yr'  => sub { output "$_[ARG]-" },    # value
    'mo'  => sub { output "$_[ARG]-" },    # value
    'dy'  => sub { output "$_[ARG]-" },    # value
    'hr'  => sub { output "$_[ARG]-" },    # value
    'min' => sub { output "$_[ARG]" },     # value

    ###########################################################

    # Read binary data - only, this function has been removed
    # from RTF::Parser.pm. Ooops. Add it back in and PUT IN
    # A TEST.
    ###########################################################

    'bin' => sub { $_[SELF]->read_bin( $_[ARG] ) },    # value

    # \ulnone should be treated as if it were \ul0...
    ###########################################################

    'ulnone' => sub {

        $_[SELF]->do_on_char_prop( 'ul', '0', 'start' );

    },

    # Clearly we're not interested in the colour table....
    ###########################################################

    'colortbl' => \&discard_content,

    # The start of the font-table. There's a global(ish) flag
    # $IN_FONTTBL that influences how other parts of the module
    # work. The main thing we do is turn this flag on when we
    # get to this point. The 'push_output('nul')' also turns
    # off any output while we're in the font table.
    ###########################################################

    'fonttbl' => sub {

        if ( $_[EVENT] eq 'start' ) {

            # Set the global flag
            $IN_FONTTBL = 1;

            # Turn off output
            push_output('nul');

            # Remember that this event has fired, and close it
            # when we go out of scope.
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            $IN_FONTTBL = 0;
            pop_output();

        }

    },

    ###########################################################

    # We seem to not want anything to do with the filetable
    # either - I guess the reason we define a control for it
    # (because otherwise it'd get skipped as an unknow destination
    # I think) is so that subclassers can handle it if they
    # want.
    ###########################################################

    'filetbl' => sub {

        #trace "$#control $_[CONTROL] $_[ARG] $_[EVENT]";
        if ( $_[EVENT] eq 'start' ) {

            push_output('nul');
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            pop_output();

        }

    },

    ###########################################################

    # A font control - highly context-dependant control word ... Can be used
    # to introduce a font definition when we're in the font-table, to specify
    # which font a style uses in the style-table, or to change the font we're
    # currently using when used as a paragraph/character property.
    ###########################################################

    'f' => sub {

        use constant FONTTBL_TRACE =>
            0;    # if you want to see the fonttbl of the document

        # We're in the middle of the font-table, so this is a font definition.
        # We're only really interested in what happens when we pass *out* of
        # scope, because at that point we'll have grabbed the font-name. I'd
        # like to add panose support at some point.

        if ($IN_FONTTBL) {

            if ( $_[EVENT] eq 'start' ) {

                # Add a new element to the output stack that we can
                # snarf back in a minute when we hit the group close

                push_output();

                # Say we're open

                $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

            } else {

                # Grab the element from the output stack, which'll be
                # our fontname

                my $fontname = pop_output;

                # This will be something like 'f1'

                my $fontdef = "$_[CONTROL]$_[ARG]";

                # Remove the trailing semi-colon and any space

                if ( $fontname =~ s/\s*;$// ) {

                    trace "$fontdef => $fontname" if FONTTBL_TRACE;

                    # Set the fontdef and the fontname in the font-table hash

                    $fonttbl{$fontdef} = $fontname;

                } else {

                    warn "can't analyze $fontname";

                }

            }

            return;

            # We're in the style sheet. This part doesn't make much sense
            # just yet, will come back to it. Looks like \f is being used
            # to recognise when a style definition is finished?! Bizarre.

        } elsif ($IN_STYLESHEET) {    # eg. \f1 => Normal;

            return if $styledef;      # if you have already encountered an \sn
            $styledef = "$_[CONTROL]$_[ARG]";

            if ( $_[EVENT] eq 'start' ) {

                #trace "start $_[CONTROL]$_[ARG]" if STYLESHEET;
                push_output();
                $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

            } else {

                my $stylename = pop_output;
                #trace "end\n $_[CONTROL]" if STYLESHEET;

                if ( $stylename =~ s/\s*;$// ) {

                    trace "$styledef => $stylename" if STYLESHEET_TRACE;
                    $stylesheet{$styledef} = $stylename;

                } else {

                    warn
                        "can't analyze '$stylename' ($styledef; event: $_[EVENT])";

                }

            }

            $styledef = '';
            return;

        }

        return if $styledef;    # if you have already encountered an \sn

        # This doesn't make a great deal of sense
        $styledef  = "$_[CONTROL]$_[ARG]";
        $stylename = $stylesheet{"$styledef"};
        trace "$styledef => $stylename" if STYLESHEET_TRACE;

        return unless $stylename;

        if ( $cstylename ne $stylename ) {    # notify a style changing

            if ( defined( my $action = $do_on_event{'style_change'} ) ) {

                ( $style, $newstyle ) = ( $cstylename, $stylename );
                &$action;

            }

        }

        $cstylename = $stylename;
        $par_props{'stylename'} = $cstylename;    # the current style

    },

    ###########################################################

    # Stylesheet - like font-table above, we set the flag, and
    # make sure we don't grab any unwanted text...

    'stylesheet' => sub {

        trace "stylesheet $#control $_[CONTROL] $_[ARG] $_[EVENT]"
            if STYLESHEET_TRACE;

        if ( $_[EVENT] eq 'start' ) {

            $IN_STYLESHEET = 1;
            push_output('nul');
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            $IN_STYLESHEET = 0;
            pop_output;

        }
    },

    ###########################################################

    # Stylesheet definition
    ###########################################################

    's' => sub {

        my ( $control, $arg, $cevent ) = ( $_[CONTROL], $_[ARG], $_[EVENT] );

        $styledef = "$_[CONTROL]$_[ARG]";

        # This looks pretty much identical to \f - only, looking at it,
        # it probably doesn't work. My head hurts.

        if ($IN_STYLESHEET) {

            if ( $_[EVENT] eq 'start' ) {

                push_output();
                $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

            } else {

                my $stylename = pop_output;
                warn "empty stylename" and return if $stylename eq '';

                if ( $stylename =~ s/\s*;$// ) {

                    trace "$styledef => $stylename|" if STYLESHEET_TRACE;
                    $stylesheet{$styledef} = $stylename;
                    $styledef = '';

                } else {

                    warn "can't analyze style name: '$stylename'";

                }

            }

            return;

        }

        $stylename = $stylesheet{"$styledef"};

        if ( ! $cstylename || $cstylename ne $stylename ) {

            if ( defined( my $action = $do_on_event{'style_change'} ) ) {

                ( $style, $newstyle ) = ( $cstylename, $stylename );

                &$action;

            }

        }

        $cstylename = $stylename;
        $par_props{'stylename'} = $cstylename;    # the current style
        trace "$styledef => $stylename" if STYLESHEET_TRACE;

    },

    ###########################################################

    # Tells us we're starting a row...
    ###########################################################

    'trowd' => sub {

        use constant TABLE_TRACE => 0;

        #print STDERR "=>Beginning of ROW\n";

        # If we're not in a table...

        unless ($IN_TABLE) {

            # Set the flag to say we now are

            $IN_TABLE = 1;

            # Fire off a table even if we have one

            if ( defined( my $action = $do_on_event{'table'} ) ) {

                $event = 'start';
                trace "table $event $text\n" if TABLE_TRACE;
                &$action;

            }

            # Add lots of output holders for various things...

            push_output();    # table content
            push_output();    # row  sequence
            push_output();    # cell sequence
            push_output();    # cell content

        }

    },

    # Perhaps the control that opens a table? Never the less,
    # an exact clone of the function above!
    ###########################################################

    'intbl' => sub {

        $par_props{'intbl'} = 1;

        unless ($IN_TABLE) {

            warn "ouverture en catastrophe" if TABLE_TRACE;
            $IN_TABLE = 1;

            if ( defined( my $action = $do_on_event{'table'} ) ) {

                $event = 'start';
                trace "table $event $text\n" if TABLE_TRACE;
                &$action;

            }

            push_output();
            push_output();
            push_output();
            push_output();

        }

    },

    # The end of a row
    ###########################################################

    'row' => sub {    # row end

        # Grab the cell and the 'cell sequence'

        $text = pop_output;
        $text = pop_output . $text;

        # Fire off the 'end cell' handler if we have one

        if ( defined( my $action = $do_on_event{'cell'} ) ) {

            $event = 'end';
            trace "row $event $text\n" if TABLE_TRACE;
            &$action;

        }

        # Grab any row text

        $text = pop_output;

        # Fire off the end-row event

        if ( defined( my $action = $do_on_event{'row'} ) ) {

            $event = 'end';
            trace "row $event $text\n" if TABLE_TRACE;
            &$action;
        }

        # Prep the next row

        push_output();
        push_output();
        push_output();

    },

    ###########################################################

    # End of a cell
    ###########################################################

    'cell' => sub {    # end of cell

        trace "process cell content: $text\n" if TABLE_TRACE;
        $text = pop_output;

        # Fire the paragraph handler

        if ( defined( my $action = $do_on_event{'par'} ) ) {

            ( $style, $event, ) = ( 'par', 'end', );
            &$action;

        } else {

            warn "$text";

        }

        $text = pop_output;

        # Fire the end-cell handler

        if ( defined( my $action = $do_on_event{'cell'} ) ) {

            $event = 'end';
            trace "cell $event $text\n" if TABLE_TRACE;
            &$action;

        }
        # prepare next cell
        push_output();
        push_output();
        trace "\@output_stack in table: ", @output_stack + 0 if STACK_TRACE;

    },

    ###########################################################

    # And thus the paragraph ends
    ###########################################################

    'par' => sub {    # END OF PARAGRAPH

        trace "($_[CONTROL], $_[ARG], $_[EVENT])" if STYLE_TRACE;

        # Close a table. Add to $text, and call even handlers
        # for cell, row, and table, in order.

        if ( $IN_TABLE and not $par_props{'intbl'} ) {    # End of Table

            $IN_TABLE = 0;
            my $next_text = pop_output;    # next paragraph content

            $text = pop_output;
            $text = pop_output . "$text";

            if ( defined( my $action = $do_on_event{'cell'} ) ) {  # end of cell

                $event = 'end';
                trace "cell $event $text\n" if TABLE_TRACE;
                &$action;

            }

            $text = pop_output;

            if ( defined( my $action = $do_on_event{'row'} ) ) {    # end of row

                $event = 'end';
                trace "row $event $text\n" if TABLE_TRACE;
                &$action;

            }

            $text = pop_output;

            if ( defined( my $action = $do_on_event{'table'} ) )
            {    # end of table

                $event = 'end';
                trace "table $event $text\n" if TABLE_TRACE;
                &$action;

            }

            push_output();
            trace "end of table ($next_text)\n" if TABLE_TRACE;
            output($next_text);

        } else {

            #push_output();

        }

        # paragraph style
        if ( defined($cstylename) and $cstylename ne '' )
        {    # end of previous style

            $style = $cstylename;

        } else {

            $cstylename = $style = 'par';    # no better solution

        }

        $par_props{'stylename'} = $cstylename;    # the current style

        if ( $par_props{intbl} ) {                # paragraph in tbl

            trace "process cell content: $text\n" if TABLE_TRACE;

            if ( defined( my $action = $do_on_event{$style} ) ) {

                ( $style, $event, $text ) = ( $style, 'end', pop_output );
                &$action;

            } elsif ( defined( $action = $do_on_event{'par'} ) ) {

                #($style, $event, $text) = ('par', 'end', pop_output);
                ( $style, $event, $text ) = ( $style, 'end', pop_output );
                &$action;

            } else {

                warn;

            }

            push_output();

            #} elsif (defined (my $action = $do_on_event{'par_styles'})) {
        } elsif ( defined( my $action = $do_on_event{$style} ) ) {

            ( $style, $event, $text ) = ( $style, 'end', pop_output );
            &$action;
            flush_top_output();
            push_output();

        } elsif ( defined( $action = $do_on_event{'par'} ) ) {

            #($style, $event, $text) = ('par', 'end', pop_output);
            ( $style, $event, $text ) = ( $style, 'end', pop_output );
            &$action;
            flush_top_output();
            push_output();

        } else {

            trace "no definition for '$style' in %do_on_event\n" if STYLE_TRACE;
            flush_top_output();
            push_output();

        }
        # redefine this!!!
        $cli      = $par_props{'li'};
        $styledef = '';
        $par_props{'bullet'} = $par_props{'number'} = $par_props{'tab'} = 0;   #

    },
    # Resets to default paragraph properties
    # Stop inheritence of paragraph properties

    'pard' => sub {

        # !!!-> reset_par_props()
        foreach (qw(qj qc ql qr intbl li)) {

            $par_props{$_} = 0;

        }

        foreach (qw(list_item)) {

            $par_props{$_} = '';

        }

    },

    # ###########################

    'pn' => sub {    # Turn on PARAGRAPH NUMBERING

        #trace "($_[CONTROL], $_[ARG], $_[EVENT])" if TRACE;

        if ( $_[EVENT] eq 'start' ) {

            %pn = ();
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            # I don't like this!!! redesign the parser???
            trace("Level: $pn{level} - Type: $pn{type} - Bullet: $pn{bullet}")
                if LIST_TRACE;
            $par_props{list_item} = \%pn;

        }

    },

    'pnlvl' => sub {    # Paragraph level $_[ARG] is a level from 1 to 9

        $pn{level} = $_[ARG];

    },

    'pnlvlbody' => sub {    # Paragraph level 10

        $pn{level} = 10;

    },

    'pnlvlblt' => sub {     # Paragraph level 11, processs the 'pntxtb' group

        $pn{level} = 11;    # bullet

    },

    'pntxtb' => sub {

        if ( $_[EVENT] eq 'start' ) {

            push_output();
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            $pn{'bullet'} = pop_output();

        }

    },

    'pntxta' => sub {

        if ( $_[EVENT] eq 'start' ) {

            push_output();
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            pop_output();

        }

    },
    # Numbering Types
    'pncard' => sub {    # Cardinal numbering: One, Two, Three
        $pn{type} = $_[CONTROL];
    },

    'pndec' => sub {     # Decimal numbering: 1, 2, 3
        $pn{type} = $_[CONTROL];
    },

    'pnucltr' => sub {    # Uppercase alphabetic numbering
        $pn{type} = $_[CONTROL];
    },

    'pnlcltr' => sub {    # Lowercase alphabetic numbering
        $pn{type} = $_[CONTROL];
    },

    'pnucrm' => sub {     # Uppercase roman numbering
        $pn{type} = $_[CONTROL];
    },

    'pnlcrm' => sub {     # Lowercase roman numbering
        $pn{type} = $_[CONTROL];
    },

    'pntext' => sub {     # ignore text content

        if ( $_[EVENT] eq 'start' ) {

            push_output();
            $control[TOP]->{"$_[CONTROL]$_[ARG]"} = 1;

        } else {

            pop_output();

        }

    },
    #'tab' => sub { $par_props{'tab'} = 1 }, # special char

    'li' => sub {    # line indent - value

        use constant LI_TRACE => 0;
        my $indent = $_[ARG];
        $indent =~ s/^-//;
        trace "line indent: $_[ARG] -> $indent" if LI_TRACE;
        $par_props{'li'} = $indent;

    }, );
###########################################################################

use vars qw(%not_processed);

END {
    if (@control) {
        trace "END{} - Control stack not empty [size: ", @control + 0, "]: ";
        foreach my $hash (@control) {
            while ( my ( $key, $value ) = each %$hash ) {
                trace "$key => $value";
            }
        }
    }
    if ($LOG_FILE) {
        select STDERR;
        unless ( open LOG, "> $LOG_FILE" ) {
            print qq^$::BASENAME: unable to output data to "$LOG_FILE"$::EOM^;
            return 0;
        }
        select LOG;
        my ( $key, $value ) = ( '', '' );
        while ( my ( $key, $value ) = each %not_processed ) {
            printf LOG "%-20s\t%3d\n", "$key", "$value";
        }
        close LOG;
        print STDERR qq^See Informations in the "$LOG_FILE" file\n^;
    }
}
1;
__END__
