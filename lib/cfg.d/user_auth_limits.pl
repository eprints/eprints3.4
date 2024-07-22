$c->{max_login_attempts} = 10;
$c->{lockout_minutes} = 10;

$c->{reset_request_recent_hours} = 24;

$c->{max_account_requests} = 100;
$c->{max_account_requests_minutes} = 60;

$c->{password_maxlength} = 200;
$c->add_trigger( EPrints::Const::EP_TRIGGER_VALIDATE_FIELD, sub
{
        my( %args ) = @_;
        my( $repo, $field, $user, $value, $problems ) = @args{qw( repository field dataobj value problems )};

    return unless defined $user && $user->isa( "EPrints::DataObj::User" ) && $field->type eq "secret";

    my $password;
    foreach my $key ( keys %{ $repo->{query}->{param} } )
    {
        my $fieldname = $field->name;
        if ( $key =~ m/$fieldname$/ )
        {
            $password = $repo->{query}->{param}->{$key}->[0];
            last;
        }
    }

    if ( defined $password && defined $repo->config( "password_maxlength" ) && length( $password ) > $repo->config( "password_maxlength" ) )
        {
        my $fieldname = $repo->xml->create_element( "span", class=>"ep_problem_field:".$field->get_name );
            $fieldname->appendChild( $field->render_name( $repo ) );
            my $maxlength_el = $repo->make_text( $repo->config( "password_maxlength" ) );
                push @$problems, $repo->html_phrase( "validate:password_too_long",
                        fieldname => $fieldname,
                        maxlength => $maxlength_el,
                );
        }
}, priority => 1000 );

$c->{login_monitoring}->{enabled} = 1;
#$c->{login_monitoring}->{fields} = [ 'timestamp', 'username', 'password_length', 'ip', 'user_agent', 'target', 'status', 'userid', 'securecode' ];
#$c->{login_monitoring}->{function} = sub {
#   my ( $fh, $repo, $timestamp, $username, $password, $status ) = @_;
#   my $password_length = length( $password );
#   my $userid = '';
#   my $securecode = '';
#   if ( $status eq "success" )
#   {
#       $userid = $repo->user_by_username( $username )->id;
#       $securecode = EPrints::Apache::AnApache::cookie( $repo->get_request, EPrints::DataObj::LoginTicket->secure_session_key( $repo ) );
#       $password_length = '';
#   }
#   print $fh "\"$timestamp\",\"$username\",\"$password_length\",\"".$repo->remote_ip."\",\"".$repo->get_request->headers_in->{ "User-Agent" }."\",\"".$repo->param( "target" )."\",\"$status\",\"$userid\",\"$securecode\"\n";
#   close( $fh );
#   return 1;
#};

=head1 COPYRIGHT

=for COPYRIGHT

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

