######################################################################
#
# EPrints::Database::mysql
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Database::mysql> - custom database methods for MySQL DB

=head1 DESCRIPTION

MySQL database wrapper.

Foreign keys will be defined if you use a DB engine that supports them 
(e.g. InnoDB).

=head2 Synopsis

    $c->{dbdriver} = 'mysql';
    # $c->{dbhost} = 'localhost';
    # $c->{dbport} = '3316';
    $c->{dbname} = 'myrepo';
    $c->{dbuser} = 'bob';
    $c->{dbpass} = 'asecret';
    # $c->{dbengine} = 'InnoDB';

=head2 MySQL-specific Annoyances

MySQL does not support sequences.

MySQL is (by default) lax about truncation.

=head1 CONSTANTS

See L<EPrints::Database|EPrints::Database#CONSTANTS>.

=head1 INSTANCE VARIABLES

See L<EPrints::Database|EPrints::Database#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################


package EPrints::Database::mysql;

use EPrints;

use EPrints::Database qw( :sql_types );
@ISA = qw( EPrints::Database );

our $I18L = {
	en => {
		collate => "utf8_general_ci",
	},
	de => {
		collate => "utf8_unicode_ci",
	},
};

binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );

use strict;

######################################################################
=pod

=over 4

=item $version = $db->get_server_version

Returns the database server version.

=cut
######################################################################

sub get_server_version
{
	my( $self ) = @_;

	my $sql = "SELECT VERSION();";
	my( $version ) = $self->{dbh}->selectrow_array( $sql );
	return "MySQL $version";
}

######################################################################
=pod

=item $version = $db->mysql_version_from_dbh

Returns the MySQL database server version from handle C<$dbh>.

=cut
######################################################################

sub mysql_version_from_dbh
{
	my( $dbh ) = @_;
	my $sql = "SELECT VERSION();";
	my( $version ) = $dbh->selectrow_array( $sql );
	$version =~ m/^(\d+).(\d+).(\d+)/;
	return $1*10000+$2*100+$3;
}

######################################################################
=pod

=item $version = $db->create( $username, $password )

Creates EPrints database as user with C<$username> and C<$password>.

=cut
######################################################################

sub create
{
	my( $self, $username, $password ) = @_;

	my $repo = $self->{session}->get_repository;

	my $dbh = DBI->connect( EPrints::Database::build_connection_string( 
			dbdriver => "mysql",
			dbhost => $repo->get_conf("dbhost"),
			dbsock => $repo->get_conf("dbsock"),
			dbport => $repo->get_conf("dbport"),
			dbname => "mysql", ),
	        $username,
	        $password,
			{
				AutoCommit => 1,
				RaiseError => 0,
				PrintError => 0,
			} );

	return undef if !defined $dbh;

	$dbh->{RaiseError} = 1;

	my $dbuser = $repo->get_conf( "dbuser" );
	my $dbpass = $repo->get_conf( "dbpass" );
	my $dbname = $repo->get_conf( "dbname" );

	my $rc = 1;
	
        $rc &&= $dbh->do( "CREATE DATABASE IF NOT EXISTS ".$dbh->quote_identifier( $dbname )." DEFAULT CHARACTER SET ".$dbh->quote( $self->get_default_charset ) );

        my( $current_user ) = $dbh->selectrow_array( "SELECT CURRENT_USER();" );
        my @local_user_host = split( '@', $current_user );

        $rc &&= $dbh->do( "CREATE USER ".$dbh->quote_identifier( $dbuser )."\@".$dbh->quote( $local_user_host[1] )." IDENTIFIED BY ".$dbh->quote( $dbpass ) );

        $rc &&= $dbh->do( "GRANT ALL PRIVILEGES ON ".$dbh->quote_identifier( $dbname ).".* TO ".$dbh->quote_identifier( $dbuser )."\@".$dbh->quote( $local_user_host[1] ) );

	$dbh->disconnect;

	$self->connect();

	return 0 if !defined $self->{dbh};

	return $rc;
}

######################################################################
=pod

=item $n = $db->create_counters()

Creates and initialises the counters.

=cut
######################################################################

sub create_counters
{
	my( $self ) = @_;

	my $counter_ds = $self->{session}->get_repository->get_dataset( "counter" );
	
	# The table creation SQL
	my $table = $counter_ds->get_sql_table_name;
	
	my $rc = $self->_create_table( $table, ["countername"], [
		$self->get_column_type( "countername", SQL_VARCHAR, SQL_NOT_NULL , 255 ),
		$self->get_column_type( "counter", SQL_INTEGER, SQL_NOT_NULL ),
	]);

	$rc &&= $self->SUPER::create_counters();
	
	# Everything OK
	return $rc;
}

######################################################################
=pod

=item $boolean = $db->has_table( $tablename )

Returns C<true> if the table with C<$tablename> exists in the 
database.

=cut
######################################################################

sub has_table
{
	my( $self, $tablename ) = @_;

	my $sth = $self->prepare("SHOW TABLES LIKE ".$self->quote_value($tablename));
	$sth->execute;
	my $rc = defined $sth->fetch ? 1 : 0;
	$sth->finish;

	return $rc;
}

######################################################################
=pod

=item $boolean = $db->has_column( $table, $column )

Returns C<true> if named C<$table> has named C<$column> in the 
database.

=cut
######################################################################

sub has_column
{
	my( $self, $table, $column ) = @_;

	my $rc = 0;

	my $sth = $self->{dbh}->column_info( undef, undef, $table, '%' );
	while(!$rc && (my $row = $sth->fetch))
	{
		my $column_name = $row->[$sth->{NAME_lc_hash}{column_name}];
		$rc = 1 if $column_name eq $column;
	}
	$sth->finish;

	return $rc;
}

######################################################################
=pod

=item $db->connect()

Connects to the database.

=cut
######################################################################

sub connect
{
	my( $self ) = @_;

	my $rc = $self->SUPER::connect();

	if( $rc )
	{
		# always try to reconnect
		$self->{dbh}->{mysql_auto_reconnect} = 1;

		$self->do("SET NAMES 'utf8'");
		$self->do('SET @@session.optimizer_search_depth = 3;');
	}
	elsif( $DBI::err == 1040 )
	{
		EPrints->abort( "Error connecting to MySQL server: $DBI::errstr. To fix this increase max_connections in my.cnf:\n\n[mysqld]\nmax_connections=300\n" );
	}

	return $rc;
}


######################################################################
=pod

=item $success = $db->has_counter( $counter )

Returns C<true> if C<$counter> exists.

=cut
######################################################################

sub has_counter
{
	my( $self, $name ) = @_;

	my $sql = "SELECT 1 FROM `counters` WHERE `countername`=".$self->quote_value( $name );

	my $sth = $self->prepare($sql);
	$self->execute( $sth, $sql );

	return defined $sth->fetch;
}


######################################################################
=pod

=item $success = $db->create_counter( $name )

Create and initialise to zero a new counter with C<$name>.

=cut
######################################################################

sub create_counter
{
	my( $self, $name ) = @_;

	return $self->insert( "counters", ["countername", "counter"], [$name, 0] );
}


######################################################################
=pod

=item $success = $db->drop_counter( $name )

Destroy the counter named C<$name>.

=cut
######################################################################

sub drop_counter
{
	my( $self, $name ) = @_;

	return $self->delete_from( "counters", ["countername"], [$name] );
}


######################################################################
=pod

=item $success = $db->remove_counters

Destroy all counters.

=cut
######################################################################

sub remove_counters
{
	my( $self ) = @_;

	my $counter_ds = $self->{session}->get_repository->get_dataset( "counter" );
	my $table = $counter_ds->get_sql_table_name;
	
	$self->drop_table( $table );
}

######################################################################
=pod

=item $n = $db->counter_next( $counter )

Return the next unused value for the named counter. Returns undef if 
the counter doesn't exist.

=cut
######################################################################

sub counter_next
{
	my( $self, $counter ) = @_;

	my $ds = $self->{session}->get_repository->get_dataset( "counter" );

	# Update the counter
	my $table = $ds->get_sql_table_name;
	my $sql = "UPDATE ".$self->quote_identifier($table)." SET counter=".
		"LAST_INSERT_ID(counter+1) WHERE ".$self->quote_identifier("countername")." = ".$self->quote_value($counter);
	
	# Send to the database
	my $rows_affected = $self->do( $sql );

	# Return with an error if unsuccessful
	return( undef ) unless( $rows_affected==1 );

	# Get the value of the counter
	$sql = "SELECT LAST_INSERT_ID();";
	my @row = $self->{dbh}->selectrow_array( $sql );

	return( $row[0] );
}

######################################################################
=pod

=item $db->counter_minimum( $counter, $value )

Ensure that the counter is set no lower that $value. This is used when
importing eprints which may not be in scrict sequence.

=cut
######################################################################

sub counter_minimum
{
	my( $self, $counter, $value ) = @_;

	my $ds = $self->{session}->get_repository->get_dataset( "counter" );

	$value+=0; # ensure numeric!

	# Update the counter to be at least $value
	my $sql = "UPDATE ".$ds->get_sql_table_name()." SET counter="
		. "CASE WHEN $value>counter THEN $value ELSE counter END"
		. " WHERE countername = ".$self->quote_value($counter);
	$self->do( $sql );
}


######################################################################
=pod

=item $db->counter_reset( $counter )

Return the counter. Use with cautiuon.

=cut
######################################################################

sub counter_reset
{
	my( $self, $counter ) = @_;

	my $ds = $self->{session}->get_repository->get_dataset( "counter" );

	# Update the counter	
	my $sql = "UPDATE ".$ds->get_sql_table_name()." ";
	$sql.="SET counter=0 WHERE countername = ".$self->quote_value($counter);
	
	# Send to the database
	$self->do( $sql );
}

sub _cache_from_SELECT
{
	my( $self, $cachemap, $dataset, $select_sql ) = @_;

	my $cache_table  = $cachemap->get_sql_table_name;
	my $Q_pos = $self->quote_identifier( "pos" );
	my $key_field = $dataset->get_key_field();
	my $Q_keyname = $self->quote_identifier($key_field->get_sql_name);

	$self->do("SET \@i=0");

	my $sql = "";
	$sql .= "INSERT INTO ".$self->quote_identifier( $cache_table );
	$sql .= "($Q_pos, $Q_keyname)";
	$sql .= " SELECT \@i:=\@i+1, $Q_keyname";
	# MariaDB does not order sub-queries unless limited. Using limit of 2^31-1 in case any system is using a signed 32-bit integer.
	my $limit = " LIMIT 2147483647";
        $limit = "" if $select_sql =~ /LIMIT/;
        $sql .= " FROM ($select_sql$limit) ".$self->quote_identifier( "S" );

	$self->do( $sql );
}


######################################################################
=pod

=item $charset = $db->get_default_charset

Return the character set to use.  Always C<utf8>.

=cut
######################################################################

sub get_default_charset { "utf8" }


######################################################################
=pod

=item $collation = $db->get_default_collation( $lang )

Return the collation to use for language C<$lang>. Always C<utf8_bin>.

=cut
######################################################################

sub get_default_collation
{
	my( $self, $langid ) = @_;

	return "utf8_bin";
}


######################################################################
=pod

=item @columns = $db->get_primary_key( $table )

Returns a list of column names that comprise the primary key for
named named C<$table>.

Returns an empty list if no primary key exists.

=cut
######################################################################

sub get_primary_key
{
	my( $self, $table ) = @_;

	my $sth = $self->prepare( "DESCRIBE ".$self->quote_identifier($table) );
	$sth->execute;

	my @COLS;
	while(my $row = $sth->fetch)
	{
		push @COLS, $row->[0] if $row->[3] eq 'PRI';
	}

	return @COLS;
}


######################################################################
=pod

=item $num_keys = $db->get_number_of_keys( $table )

Returns the number of columns which are keys (C<PRI>, C<MUL> or 
C<UNI>) for named C<$table>.

=cut
######################################################################

sub get_number_of_keys
{
	my( $self, $table ) = @_;
	my $sth = $self->prepare( "DESCRIBE ".$self->quote_identifier($table) );
        $sth->execute;

        my $NUM_KEYS = 0;
        while(my $row = $sth->fetch)
	{
		if ( $row->[3] eq 'PRI' or $row->[3] eq 'MUL' or $row->[3] eq 'UNI' ) 
		{
			++$NUM_KEYS;
		}
	}
	return $NUM_KEYS;
}

######################################################################
=pod

=item $collation = $db->get_column_colation( $table, $column )

Returns the collation for the named C<$column> in the named C<$table>.

=cut
######################################################################

sub get_column_collation
{
	my( $self, $table, $column ) = @_;

	my $sth = $self->prepare( "SHOW FULL COLUMNS FROM ".$self->quote_identifier($table)." LIKE ".$self->quote_value($column) );
	$sth->execute;

	my $collation;
	while(my $row = $sth->fetch)
	{
		$collation = $row->[$sth->{NAME_lc_hash}{"collation"}];
	}

	return $collation;
}


######################################################################
=pod

=item $str = $db->quote_identifier( @parts )

Quote a database identifier (e.g. table names). Multiple C<@parts>
will be joined by dots (C<.>).

We'll do quote here, because L<DBD::mysql#quote_identifier> is really 
slow.

=cut
######################################################################

sub quote_identifier
{
	my( $self, @parts ) = @_;

	# we shouldn't get identifiers with '`' in
	return join(".", map {
		$_ =~ m/`/ ?
			EPrints::abort "Bad character in database identifier: $_" :
			"`$_`"
		} @parts);
}

sub _rename_table_field
{
	my( $self, $table, $field, $old_name ) = @_;

	my $rc = 1;

	my @names = $field->get_sql_names;
	my @types = $field->get_sql_type( $self->{session} );

	# work out what the old columns are called
	my @old_names;
	{
		local $field->{name} = $old_name;
		@old_names = $field->get_sql_names;
	}

	my @column_sql;
	for(my $i = 0; $i < @names; ++$i)
	{
		push @column_sql, sprintf("CHANGE %s %s",
				$self->quote_identifier($old_names[$i]),
				$types[$i]
			);
	}
	
	$rc &&= $self->do( "ALTER TABLE ".$self->quote_identifier($table)." ".join(",", @column_sql));

	return $rc;
}

sub _rename_field_ordervalues_lang
{
	my( $self, $dataset, $field, $old_name, $langid ) = @_;

	my $order_table = $dataset->get_ordervalues_table_name( $langid );

	my $sql_field = $field->create_ordervalues_field( $self->{session}, $langid );

	my( $col ) = $sql_field->get_sql_type( $self->{session} );

	my $sql = sprintf("ALTER TABLE %s CHANGE %s %s",
			$self->quote_identifier($order_table),
			$self->quote_identifier($old_name),
			$col
		);

	return $self->do( $sql );
}


######################################################################
=pod

=item $sql = $db->prepare_regexp( $col, $value )

Oracle use the syntax:

 $col REGEXP $value

For the quoted regexp C<$value> and the quoted column C<$col>.

=cut
######################################################################

sub prepare_regexp
{
	my( $self, $col, $value ) = @_;

	return "$col REGEXP $value";
}

######################################################################
=pod

=item $sql = $db->sql_LIKE()

Returns the syntactic glue to use when making a case-insensitive
C<LIKE> using C<utf8_general_ci> collation.

=cut
######################################################################

sub sql_LIKE
{
	my( $self ) = @_;

	return " COLLATE utf8_general_ci LIKE ";
}


######################################################################
=pod

=item $value = $db->ci_lookup( $field, $value )

This is a hacky method to support case-insensitive lookup for
usernames, emails, etc.  It returns the actual case-sensitive version
of C<$value> if there is a case-insensitive match for the C<$field>.

=cut
######################################################################

sub ci_lookup
{
	my( $self, $field, $value ) = @_;

	return if !defined $value; # Can't do a CI match on 'NULL'

	my $table = $field->dataset->get_sql_table_name;
	
	my $sql =
		"SELECT ".$self->quote_identifier( $field->get_sql_name ).
		" FROM ".$self->quote_identifier( $table ).
		" WHERE ".$self->quote_identifier( $field->get_sql_name )."=".$self->quote_value( $value )." COLLATE utf8_general_ci";

	my $sth = $self->prepare( $sql );
	$self->execute( $sth, $sql );

	my( $real_value ) = $sth->fetchrow_array;

	$sth->finish;

	return defined $real_value ? $real_value : $value;
}

######################################################################
=pod

=item $boolean = $db->duplicate_error()

Returns a boolean for whether the database error is a duplicate error.
Based on whether the L<DBI#err> code is C<1062>.

=cut
######################################################################

sub duplicate_error { $DBI::err == 1062 }


######################################################################
=pod

=item $boolean = $db->duplicate_error()

Returns a boolean for whether the database error is a retry error.
Based on whether the L<DBI#err> code is C<2006>.

=cut
######################################################################

sub retry_error { $DBI::err == 2006 }


######################################################################
=pod

=item $type_info = $db->type_info( $data_type )

See L<DBI/type_info>.

Uses C<LONGTEXT> with column size 2^31 for C<SQL_CLOB>.

=cut
######################################################################

sub type_info
{
	my( $self, $data_type ) = @_;

	if( $data_type eq SQL_CLOB )
	{
		return {
			TYPE_NAME => "longtext",
			CREATE_PARAMS => "",
			COLUMN_SIZE => 2 ** 31,
		};
	}
	else
	{
		return $self->SUPER::type_info( $data_type );
	}
}



######################################################################
=pod

=item $name = $db->index_name( $table, @cols )

Returns the name of the first index that starts with named columns
C<@cols> in the named C<$table>.

Returns C<undef> if no index exists.

Uses MySQL 4.0+ compatible C<SHOW INDEX>.

This method gets the entire C<SHOW INDEX> response and builds a 
look-up table of keys with their C<ordered> columns. This ensures even 
if MySQL is weird and returns out of order results we won't break.

=cut
######################################################################

sub index_name
{
	my( $self, $table, @cols ) = @_;

	my $hash = sub { join ':', map { $self->quote_identifier( $_ ) } @_ }; 

	my $needle = &$hash( @cols );
	my %indexes;

	my $sth = $self->prepare("SHOW INDEX FROM ".$self->quote_identifier( $table ));
	$sth->execute;

	my( $key_name, $seq, $col_name );
	$sth->bind_col( $sth->{NAME_uc_hash}->{KEY_NAME} + 1, \$key_name );
	$sth->bind_col( $sth->{NAME_uc_hash}->{SEQ_IN_INDEX} + 1, \$seq );
	$sth->bind_col( $sth->{NAME_uc_hash}->{COLUMN_NAME} + 1, \$col_name );

	while($sth->fetch)
	{
		$indexes{$key_name} ||= [];
		$indexes{$key_name}[$seq - 1] = $col_name;
	}
	foreach $key_name (keys %indexes)
	{
		return $key_name if
			$needle eq &$hash( @{$indexes{$key_name}} );
	}

	return undef;
}

sub _create_table
{
	my( $self, $table, $primary_key, $columns ) = @_;

	my $sql = "";

	$sql .= "CREATE TABLE ".$self->quote_identifier($table)." (";
	$sql .= join(', ', @$columns);
	if( @$primary_key )
	{
		$sql .= ", PRIMARY KEY(".join(', ', map { $self->quote_identifier($_) } @$primary_key).")";
	}
	$sql .= ")";
	$sql .= " DEFAULT CHARSET=".$self->get_default_charset;
	
	my $engine = $self->{session}->config( "dbengine" );
	$sql .= " ENGINE=$engine" if $engine;

	return $self->do($sql);
}

1; # For use/require success

######################################################################
=pod

=back

=cut

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

