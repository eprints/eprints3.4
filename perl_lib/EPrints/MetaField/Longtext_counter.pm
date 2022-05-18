######################################################################
#
# EPrints::MetaField::Longtext_counter;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Longtext_counter> Longtext input field with character counter.

=head1 DESCRIPTION
Renders the input field with additional character counter.
Requires javascript/jquery.min.js in static folder. 
This will define jquery $ as $j to avoid conflict with prototype.

=over 4

=cut

package EPrints::MetaField::Longtext_counter;

use strict;
use warnings;

BEGIN
{
        our( @ISA );

        @ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;



sub get_basic_input_elements
{
        my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

        my %defaults = $self->get_property_defaults;

        my @classes = defined $self->{dataset} ?
                join('_', 'ep', $self->dataset->base_id, $self->name) :
                ();

	my %attributes = (
                name => $basename,
                id => $basename,
                class => join(' ', @classes),
                rows => $self->{input_rows},
                cols => $self->{input_cols},
                maxlength => $self->{maxlength},
                wrap => "virtual",
		'aria-labelledby' => $self->get_labelledby( $basename ),
	);
	my $describedby = $self->get_describedby( $basename, $one_field_component );
        $attributes{'aria-describedby'} = $describedby if EPrints::Utils::is_set( $describedby );
	my $textarea = $session->make_element( "textarea", %attributes );
        $textarea->appendChild( $session->make_text( $value ) );

        my $frag = $session->make_doc_fragment;
        $frag->appendChild($textarea);

        my $p = $session->make_element( "p", id=>$basename . "_counter_line" );
        $p->appendChild($session->make_element( "span", id=>$basename."_display_count"));
        if (($self->{maxwords}) ne $defaults{maxwords})
        {
                $p->appendChild( $session->make_text( "/".$self->{maxwords} ) );
        }
	$p->appendChild( $session->html_phrase( "lib/metafield:words" ) );
        $frag->appendChild( $p );


$frag->appendChild( $session->make_javascript( <<EOJ ) );
jQuery.noConflict();
function getWordCount(words_string)
{
	var words = words_string.split(/\\W+/);
        var word_count = words.length;
        if (word_count > 0 && words[word_count-1] == "")
        {
                word_count--;
        }
	return word_count;
}
jQuery.fn.wordCount = function(max_words)
{
	var counterLine = "counter_line";
        var counterElement = "display_count";
        var cid = jQuery(this).attr('id');
        var total_words;

        //for each keypress function on text areas
        jQuery(this).bind("input propertychange", function()
        {
		total_words = getWordCount(this.value);
                jQuery('#'+cid+"_"+counterElement).html(total_words);
		console.log("total_words: "+total_words+" | max_words: "+max_words);
		if (total_words > max_words )
		{
			jQuery('#'+cid+"_"+counterLine).attr('class', 'ep_over_word_limit');
		}
		else if (jQuery('#'+cid+"_"+counterLine).attr('class') == "ep_over_word_limit")
		{
			jQuery('#'+cid+"_"+counterLine).attr('class', '');
		}
        });
	total_words = getWordCount(jQuery(this).text());
        jQuery('#'+cid+"_"+counterElement).html(total_words);
};
jQuery( document ).ready(function() {
	jQuery("#$basename").wordCount($self->{maxwords});
});
EOJ


        return [ [ { el=>$frag } ] ];
}

sub get_property_defaults
{
        my( $self ) = @_;
        my %defaults = $self->SUPER::get_property_defaults;
        $defaults{maxwords} = 500;
        return %defaults;
}





######################################################################
1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END
