######################################################################
#
# refering to http://threader.ecs.soton.ac.uk/lists/eprints_tech/1215.html, http://threader.ecs.soton.ac.uk/lists/eprints_tech/21544/attachment/default
# as well as http://threader.ecs.soton.ac.uk/lists/eprints_tech/18088.html, i.e.
# https://wiki.eprints.org/w/Category:EPrints_Metadata_Fields#Ordering.2C_Indexing_and_Searching
# following functions
# make_name_orderkey, make_title_orderkey, make_value_orderkey
# manipulate the diacritics et al. for ordering purpose
# to allow appropriate setting of make_value_orderkey or make_single_value_orderkey
#
######################################################################

$c->{make_orderkey_ignore_extras} = sub
{
        my ($name) = @_;

        my  @orderkey;
        # convert to upper case ASCII
        my $orderkey = uc( unidecode( $name ) );
        # keep separating dot (of initials from given name)
        $orderkey =~ s/[\.]/_/g;
        # ignore anything else than alphanumeric characters, aka non-word characters, except _
        $orderkey =~ s/[^_A-Z0-9]//g;
        return $orderkey;
};

$c->{make_name_orderkey} = sub
{
	my ($field, $value, $session, $langid, $dataset) = @_;

	# Safeguard in case used on non-compound field
	return unless ref($value) eq 'HASH';
	
 	my  @orderkey;
        foreach( "family", "given", "honourific" )
        # foreach( "family", "lineage", "given", "honourific" )
        {
		next unless defined($value->{$_}) && $value->{$_} ne "";
		my $name = $value->{$_};

		# convert name appropriately
		my $orderkey = &$c->{make_orderkey_ignore_extras}( $name );
                push  @orderkey, $orderkey;
         }
         return join( "_" ,  @orderkey );
};

$c->{make_title_orderkey} = sub
{
        my( $field, $value, $dataset ) = @_;

        $value =~ s/^[^a-z0-9]+//gi;
        if( $value =~ s/^(a|an|the) [^a-z0-9]*//i ) { $value .= ", $1"; }

        return &$c->{make_orderkey_ignore_extras}( $value );
};

$c->{make_sanitised_value_orderkey} = sub
{
	my ($field, $value, $session, $langid, $dataset) = @_;

	# convert name appropriately
	my $orderkey = &$c->{make_orderkey_ignore_extras}( $value );
	return $orderkey;
};
