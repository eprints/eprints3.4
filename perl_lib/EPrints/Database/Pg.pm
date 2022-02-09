######################################################################
#
# EPrints::Database::Pg
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Database::Pg> - custom database methods for PostgreSQL DB

=head1 DESCRIPTION

PostgreSQL database wrapper.

=head2 Synopsis

    $c->{dbdriver} = 'Pg';
    # $c->{dbhost} = 'localhost';
    $c->{dbname} = 'myrepo';
    $c->{dbuser} = 'bob';
    $c->{dbpass} = 'asecret';
    $c->{dbschema} = 'eprints';

=head2 PostgreSQL-specific Annoyances

The L<DBD::Pg> C<SQL_VARCHAR> type is mapped to C<TEXT> instead of 
C<VARCHAR(n)>.

=head1 CONSTANTS

See L<EPrints::Database|EPrints::Database#CONSTANTS>.

=head1 INSTANCE VARIABLES

See L<EPrints::Database|EPrints::Database#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::Database::Pg;

use EPrints::Database qw( :sql_types );
use DBD::Pg qw( :pg_types );

@ISA = qw( EPrints::Database );

use strict;


######################################################################
=pod

=over 4

=item $db->connect

Connects to the database.

=cut
######################################################################

sub connect
{
	my( $self ) = @_;

	my $rc = $self->SUPER::connect;
	return $rc if !$rc;

	$self->{dbh}->{pg_enable_utf8} = 1;

	return $rc;
}

######################################################################
=pod

=item $type_info = $db->type_info( $data_type )

See L<DBI/type_info>.

Uses C<SMALLINT> with column size 3 for C<SQL_TINYINT>.

Uses C<VARCHAR> with column size 255 for C<SQL_VARCHAR> rather than
C<TEXT> which is the default for L<DBD:Pg>.

Uses C<TEXT> with column size 2^31 for C<SQL_LONGVARCHAR> and
C<SQL_CLOB>.

Uses C<BYTEA> with column size 2^31 for C<SQL_LONGVARBINARY>.

=cut
######################################################################

sub type_info
{
	my( $self, $data_type ) = @_;

	if( $data_type eq SQL_TINYINT )
	{
		return {
			TYPE_NAME => "smallint",
			CREATE_PARAMS => "",
			COLUMN_SIZE => 3,
		};
	}
	# DBD::Pg maps SQL_VARCHAR to text rather than varchar(n)
	elsif( $data_type eq SQL_VARCHAR )
	{
		return {
			TYPE_NAME => "varchar",
			CREATE_PARAMS => "max length",
			COLUMN_SIZE => 255,
		};
	}
	elsif( $data_type eq SQL_LONGVARCHAR || $data_type eq SQL_CLOB )
	{
		return {
			TYPE_NAME => "text",
			CREATE_PARAMS => "",
			COLUMN_SIZE => 2**31,
		};
	}
	elsif( $data_type eq SQL_LONGVARBINARY )
	{
		return {
			TYPE_NAME => "bytea",
			CREATE_PARAMS => "",
			COLUMN_SIZE => 2**31,
		};
	}
	else
	{
		return $self->SUPER::type_info( $data_type );
	}
}


######################################################################
=pod

=item $db = $db->create( $username, $password )

Create and connect to a new database using user account C<$username> 
and C<$password>.

=cut
######################################################################

sub create
{
	my( $self, $username, $password ) = @_;

	my $repo = $self->{session}->get_repository;

	my $dbh = DBI->connect( EPrints::Database::build_connection_string( 
			dbdriver => "Pg",
			dbhost => $repo->get_conf("dbhost"),
			dbsock => $repo->get_conf("dbsock"),
			dbport => $repo->get_conf("dbport"),
			dbname => "postgres", ),
	        $username,
	        $password,
			{ AutoCommit => 1 } );

	return undef if !defined $dbh;

	my $dbuser = $repo->get_conf( "dbuser" );
	my $dbpass = $repo->get_conf( "dbpass" );
	my $dbname = $repo->get_conf( "dbname" );

	my $rc = 1;
	
	my( $has_dbuser ) = $dbh->selectrow_array("SELECT 1 FROM pg_user WHERE usename=?", {}, $dbuser);

	if( $has_dbuser )
	{
		$repo->log( "Warning! Database already has a user account '$dbuser'" );
	}
	else
	{
		$rc &&= $dbh->do( "CREATE USER ".$dbh->quote_identifier($dbuser)." PASSWORD ?", {}, $dbpass );
	}
	$rc &&= $dbh->do( "CREATE DATABASE ".$dbh->quote_identifier($dbname)." WITH OWNER ".$dbh->quote_identifier($dbuser)." ENCODING ?", {}, "UNICODE" );

	$dbh->disconnect;

	$self->connect();

	return 0 if !defined $self->{dbh};

	return $rc;
}


######################################################################
=pod

=item $real_type = $db->get_column_type( $name, $type, $not_null, [ $length ] )

Returns a SQL column definition for C<$name> of type C<$type>. If
C<$not_null> is C<true> the column will be set to C<NOT NULL>. For
column types that require a length use C<$length>.

C<$type> is the SQL type. The types are constants defined by this
module, to import them use:

  use EPrints::Database qw( :sql_types );

Supported types (n = requires LENGTH argument):

Character data: C<SQL_VARCHAR(n)>, C<SQL_LONGVARCHAR>.

Binary data: C<SQL_VARBINARY(n)>, C<SQL_LONGVARBINARY>.

Integer data: C<SQL_TINYINT>, C<SQL_SMALLINT>, C<SQL_INTEGER>,

Floating-point data: C<SQL_REAL>, C<SQL_DOUBLE>.

Time data: C<SQL_DATE>, C<SQL_TIME>.

=cut
######################################################################

sub get_column_type
{
	my( $self, $name, $data_type, $not_null, $length, $scale, %opts ) = @_;

	my $type = $self->SUPER::get_column_type( @_[1..$#_] );

	# character coding is DB level in PostgreSQL
	$type =~ s/ COLLATE \S+//;
	$type =~ s/ CHARACTER SET \S+//;

	return $type;
}

sub _create_table
{
	my( $self, $table, $primary_key, $columns ) = @_;

	# PostgreSQL driver always prints a warning on PRIMARY KEY
	local $SIG{__WARN__} = sub { print STDERR @_ if $_[0] !~ m/NOTICE:  CREATE TABLE/; };

	return $self->SUPER::_create_table( @_[1..$#_] );
}


######################################################################
=pod

=item $boolean = $db->has_table( $table )

Returns boolean dependent on whether the named C<$table> exists in the
database.

For PostGres C<column_info()> under L<DBD::Pg> returns reserved 
identifiers in quotes, so instead we'll query the 
C<information_schema>.

=cut
######################################################################

sub has_table
{
	my( $self, $table ) = @_;

	my $schema = $self->{session}->config( 'dbschema' ) ? $self->{session}->config( 'dbschema' ) : 'public';

	my( $rc ) = $self->{dbh}->selectrow_array( "SELECT 1 FROM information_schema.tables WHERE table_schema=? AND table_name=?", {}, $schema, $table );

	return $rc;
}


######################################################################
=pod

=item $boolean = $db->has_column( $table, $column )

Return C<true> if the named database C<$table> has the named
C<$column>.

=cut
######################################################################

sub has_column
{
	my( $self, $table, $column ) = @_;

	my( $rc ) = $self->{dbh}->selectrow_array( "SELECT 1 FROM information_schema.columns WHERE table_name=? AND column_name=?", {}, $table, $column );

	return $rc;
}


######################################################################
=pod

=item $boolean = $db->has_sequence( $name )

Return C<true> if a sequence of the given $<name> exists in the
database.

=cut
######################################################################

sub has_sequence
{
	my( $self, $name ) = @_;

	my( $rc ) = $self->{dbh}->selectrow_array( "SELECT 1 FROM pg_class WHERE relkind='S' AND relname=?", {}, $name );

	return $rc;
}


######################################################################
=pod

=item @tables = $db->get_tables

Return a list of all the tables in the database.

=cut
######################################################################

sub get_tables
{
	my( $self ) = @_;

	my $schema = $self->{session}->config( 'dbschema' ) ? $self->{session}->config( 'dbschema' ) : 'public';
	
	my $tables = $self->{dbh}->selectall_arrayref( "SELECT table_name FROM information_schema.tables WHERE table_schema=?", $schema);

	return map { @$_ } @$tables;
}


######################################################################
=pod

=item $n = $db->counter_current( $counter )

Return the value of the previous counter_next on C<$counter>.

=cut
######################################################################

sub counter_current
{
	my( $self, $counter ) = @_;

	$counter .= "_seq";

	my( $id ) = $self->{dbh}->selectrow_array("SELECT currval(?)", {}, $counter);

	return $id + 0;
}


######################################################################
=pod

=item $n = $db->counter_next( $counter )

Return the next unused value for the named C<$counter>. Returns
C<undef> if the C<$counter> doesn't exist.

=cut
######################################################################

sub counter_next
{
	my( $self, $counter ) = @_;

	$counter .= "_seq";

	my( $id ) = $self->{dbh}->selectrow_array("SELECT nextval(?)", {}, $counter);

	return $id + 0;
}


######################################################################
=pod

=item $str = $db->quote_binary( $bytes )

PostgreSQL requires transforms of binary data to work correctly.

This sets C<pg_type> to L<DBD::Pg::Pg_BYTEA> for returned C<$bytes>.

=cut
######################################################################

sub quote_binary
{
	my( $self, $bytes ) = @_;

	return [ $bytes, { pg_type => DBD::Pg::PG_BYTEA } ];
}


######################################################################
=pod

=item $sql = $db->prepare_regexp( $col, $value )

PostgreSQL use the syntax:

 $col ~* $value

For the quoted regexp C<$value> and the quoted column C<$col>.

=cut
######################################################################

sub prepare_regexp
{
	my( $self, $col, $value ) = @_;

	return "$col ~* $value";
}

sub _cache_from_SELECT
{
	my( $self, $cachemap, $dataset, $select_sql ) = @_;

	my $cache_table  = $cachemap->get_sql_table_name;
	my $cache_seq = $cache_table . "_seq";
	my $Q_pos = $self->quote_identifier( "pos" );
	my $key_field = $dataset->get_key_field();
	my $Q_keyname = $self->quote_identifier($key_field->get_sql_name);

	$self->create_sequence( $cache_seq );

	my $sql = "";
	$sql .= "INSERT INTO ".$self->quote_identifier( $cache_table );
	$sql .= "($Q_pos, $Q_keyname)";
	$sql .= " SELECT nextval(".$self->quote_value( $cache_seq )."), $Q_keyname";
	$sql .= " FROM ($select_sql) ".$self->quote_identifier( "S" );

	$self->do( $sql );

	$self->drop_sequence( $cache_seq );
}

######################################################################
=pod

=item $name = $db->index_name( $table, @cols )

Should return the name of the first index that starts with named
columns C<@cols> in the named C<$table>. However, this is not
supported by PostgreSQL so always returns C<1>.

=cut
######################################################################

sub index_name
{
	my( $self, $table, @cols ) = @_;

	return 1;
}

######################################################################
=pod

=item $sql = $db->sql_LIKE()

Returns the syntactic glue to use when making a case-insensitive
C<ILIKE>.

=cut
######################################################################

sub sql_LIKE
{
	my( $self ) = @_;

	return " ILIKE ";
}

1;

######################################################################
=pod 

=back

=head1 SEE ALSO

L<EPrints::Database>

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

