#!/usr/bin/perl
#
# update-whd-client-is-asset-admin.pl
#
# JAMF policy script to make clients admin of their own asset. Fetches asset
# clients from WHD based on the computer serial number. If $user_name is
# already part of the admin group, then do nothing. If $user_name matches one
# of the WHD asset clients (found using the hardware serial number), then
# $user_name is added to the admin group.
#
# Note that parameter 8 is false by default. If parameter 8 is true, if the
# user is already part of the admin group and not a client of the asset in WHD,
# the user is removed from the admin group. Keeping this parameter false avoids
# two extra validation queries to the WHD database (ie. if the user is already
# admin, then do nothing).
#
# Note that older MacOS versions did not include the JSON perl module, nor do
# they have Xcode installed to use the module from CPAN, so we must check for
# the existance of the JSON perl module to manage the error.
#
# JAMF script parameters:
#
#	Parameter 4: WHD hostname?
#	Parameter 5: WHD API username?
#	Parameter 6: WHD API key?
#	Parameter 7: Always admin usernames (optional)?
#	Parameter 8: Fix extra admin users (default is false)?
#
# Copyright 2023 JS Morisset <https://surniaulula.com/> and Sunshine Coast
# School District 46 <https://sd46.bc.ca/>.
#
# Authored by JS Morisset <https://surniaulula.com/>.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# See <https://www.gnu.org/licenses/> for the GNU General Public License.
#
use strict;
use warnings;
use Data::Dumper;
use LWP::UserAgent;
use IO::Socket::SSL;
use URI;

#
# Extra required modules.
#
# The JSON module is not available in old MacOS versions. If missing, we cannot
# install it from CPAN as MacOS does not have Xcode installed by default. The
# BEGIN block tells perl to run the code inside the BEGIN block as soon as that
# part of the script has finished compiling. 
#
BEGIN {

	foreach my $mod ( ( 'JSON' ) ) {

		my $mod_fname = "$mod.pm"; $mod_fname =~ s!::!/!g;
		my $mod_found = 0;

		while ( < @INC > ) {

			if ( -s "$_/$mod_fname" ) {

				$mod_found = 1;

				eval "require $mod";
			}
		}

		if ( ! $mod_found ) {

			my $mount_point     = $ARGV[ 0 ] || '';
			my $computer_name   = $ARGV[ 1 ] || '';
			my $user_name       = $ARGV[ 2 ] || '';
			my $whd_server      = $ARGV[ 3 ] || '';	# WHD hostname?
			my $whd_api_user    = $ARGV[ 4 ] || '';	# WHD API username?
			my $whd_api_key     = $ARGV[ 5 ] || '';	# WHD API key?
			my $admin_users     = $ARGV[ 6 ] || '';	# Always admin usernames (optional)?
			my $fix_extra_admin = $ARGV[ 7 ] || '';	# Fix extra admin users (default is false)?
			my $macos_version   = `/usr/bin/sw_vers -productVersion`;

			# Use 'true' and 'false' strings (instead of 1 and 0) for better status messages.
			$fix_extra_admin = ( $fix_extra_admin && 'false' ne lc( $fix_extra_admin ) ) && 'true' || 'false';

			print "\n";
			print "mount_point = $mount_point\n";
			print "computer_name = $computer_name\n";
			print "user_name = $user_name\n";
			print "whd_server = $whd_server\n";
			print "whd_api_user = $whd_api_user\n";
			print "whd_api_key = ********\n";
			print "admin_users = $admin_users\n";
			print "fix_extra_admin = $fix_extra_admin\n";
			print "macos_version = $macos_version\n";
			print "\n";
			print "error: $mod perl module is required and missing.\n\n";

			exit 1;
		}
	}

	JSON->import( qw( decode_json ) );
}

#
# Global variables.
#
# Note that WHD API connections require a tech account name. Any tech account
# name will do so long as the tech account name exists.
#
my $admin_node      = '.';
my $admin_group     = 'admin';
my $mount_point     = $ARGV[ 0 ] || '';
my $computer_name   = $ARGV[ 1 ] || '';
my $user_name       = $ARGV[ 2 ] || '';
my $whd_server      = $ARGV[ 3 ] || '';	# WHD hostname?
my $whd_api_user    = $ARGV[ 4 ] || '';	# WHD API username?
my $whd_api_key     = $ARGV[ 5 ] || '';	# WHD API key?
my $admin_users     = $ARGV[ 6 ] || '';	# Always admin usernames (optional)?
my $fix_extra_admin = $ARGV[ 7 ] || '';	# Fix extra admin users (default is false)?
my $whd_asset_url   = "https://$whd_server/helpdesk/WebObjects/Helpdesk.woa/ra/Assets/";
my $whd_client_url  = "https://$whd_server/helpdesk/WebObjects/Helpdesk.woa/ra/Clients/";
my $home_dir        = "/Users/$user_name";
my $cacert_pem      = "$home_dir/.cacert.pem";
my $macos_version   = `/usr/bin/sw_vers -productVersion`;

# Use 'true' and 'false' strings (instead of 1 and 0) for better status messages.
$fix_extra_admin = ( $fix_extra_admin && 'false' ne lc( $fix_extra_admin ) ) && 'true' || 'false';

print "\n";
print "mount_point = $mount_point\n";
print "computer_name = $computer_name\n";
print "user_name = $user_name\n";
print "whd_server = $whd_server\n";
print "whd_api_user = $whd_api_user\n";
print "whd_api_key = ********\n";
print "admin_users = $admin_users\n";
print "fix_extra_admin = $fix_extra_admin\n";
print "macos_version = $macos_version\n";
print "\n";

#
# Basic requirement checks.
#
if ( ! length( $whd_api_key ) ) {

	if ( ! length( $user_name ) ) {

		print "error: user name parameter is required.\n\n";

		exit 1;

	} elsif ( ! length( $whd_server ) ) {

		print "error: WHD hostname parameter is required.\n\n";

		exit 1;

	} elsif ( ! length( $whd_api_user ) ) {

		print "error: WHD API username parameter is required.\n\n";

		exit 1;

	} elsif ( ! length( $whd_api_key ) ) {

		print "error: WHD API key parameter is required.\n\n";

		exit 1;
	}

} elsif ( ! -d $home_dir ) {

	print "error: home folder $home_dir does not exist.\n\n";

	exit 1;
}

#
# Main section.
#
# If $user_name is already part of the admin group, then do nothing.
#
# If $user_name is part of the always admin parameter, then add $user_name to
# the admin group.
#
# If $user_name matches one of the WHD asset clients (found using the hardware
# serial number), then add $user_name to the admin group.
#
my $hw_serial_no = get_hardware_serial_number();

if ( user_is_admin() ) {	# Maybe nothing to do.

	if ( 'false' eq $fix_extra_admin || user_is_always_admin() || user_can_admin_asset() ) {	# Nothing to do.

		print "user $user_name is already admin of $computer_name ($hw_serial_no).\n";

	} else {	# Should not be admin.

		print "user $user_name should not be admin of $computer_name ($hw_serial_no).\n";

		remove_user_admin();
	}

} elsif ( user_is_always_admin() ) {
	
	print "user $user_name can always admin $computer_name ($hw_serial_no).\n";

	add_user_admin();

} elsif ( user_can_admin_asset() ) {

	print "user $user_name can admin $computer_name ($hw_serial_no).\n";

	add_user_admin();

} else {

	print "user $user_name cannot admin $computer_name ($hw_serial_no).\n";
}

print "\n";

exit 0;	# Stop here.

#
# Export the root certificates keychain to a .pem file in the user's folder for
# LWP::UserAgent.
#
sub update_user_cacert_pem {

	`/usr/bin/security export -t certs -f pemseq -k /System/Library/Keychains/SystemRootCertificates.keychain -o "$cacert_pem" 2>/dev/null`;

	if ( ! -s $cacert_pem ) {
		
		print "error: failed to export system root certificates to $cacert_pem.\n\n";

		exit 1;
	}
}

#
# Get the hardware serial number for this computer.
#
# The hardware serial number should match the asset serial number in WHD.
#
sub get_hardware_serial_number {

	#
	# decode_json() is provided by the JSON module.
	#
	my $hw_data = decode_json( `system_profiler -json SPHardwareDataType` );

	if ( ! length( $hw_data->{ SPHardwareDataType }[ 0 ]->{ serial_number } ) ) {
		
		print "error: failed to get the hardware serial number.\n\n";

		exit 1;
	}

	return $hw_data->{ SPHardwareDataType }[ 0 ]->{ serial_number };
}

#
# Check if the user name is in the local admin group.
#
# Returns 0 (false) or 1 (true).
#
sub user_is_admin {

	my $group_membership = `/usr/bin/dscl -q "$admin_node" read "/Groups/$admin_group" GroupMembership`;
	my @user_names       = split( /[, ]+/, $group_membership );

	shift( @user_names ) if $user_names[ 0 ] eq 'GroupMembership:';

	return grep( /^$user_name$/, @user_names ) ? 1 : 0;
}

#
# Check if the user name is part of the optional $admin_users parameter.
#
sub user_is_always_admin {

	my @user_names = split( /[, ]+/, $admin_users );

	return grep( /^$user_name$/, @user_names ) ? 1 : 0;
}

#
# Check if the user is a client of the asset in WHD using the hardware serial
# number.
#
# Returns 0 (false) or 1 (true).
#
sub user_can_admin_asset {

	update_user_cacert_pem();

	my @user_names = get_whd_asset_client_user_names();

	return grep( /^$user_name$/, @user_names ) ? 1 : 0;
}

#
# Add the user to the local admin group.
#
sub add_user_admin {

	print "adding $user_name to the $admin_group group...\n";

	`/usr/sbin/dseditgroup -o edit -n "$admin_node" -a "$user_name" -t user "$admin_group"`;

	if ( user_is_admin( $user_name ) ) {	# Double check, just in case.

		print "success: user $user_name is now admin of $computer_name ($hw_serial_no).\n";

	} else {

		print "error: failed to add user $user_name to the $admin_group group.\n\n";

		exit 1;
	}
}

#
# Add the user to the local admin group.
#
sub remove_user_admin {

	print "removing $user_name from the $admin_group group...\n";

	`/usr/sbin/dseditgroup -o edit -n "$admin_node" -d "$user_name" -t user "$admin_group"`;

	if ( user_is_admin( $user_name ) ) {	# Double check, just in case.

		print "error: failed to remove user $user_name from the $admin_group group.\n\n";

		exit 1;

	} else {

		print "success: user $user_name is no longer admin of $computer_name ($hw_serial_no).\n";
	}
}

#
# Get all client user names for an asset in WHD using the hardware serial
# number.
#
# Returns an array of client names.
#
sub get_whd_asset_client_user_names {

	my @client_ids = get_whd_asset_client_ids();
	my @client_user_names;

	foreach ( @client_ids ) {

		my $url = URI->new( $whd_client_url . $_ );

		$url->query_form(
			'username' => $whd_api_user,
			'apiKey'   => $whd_api_key,
		);

		my $ua = LWP::UserAgent->new();

		$ua->ssl_opts( SSL_ca_file => $cacert_pem );

		my $res = $ua->get( $url );

		if ( ! $res->is_success ) {

			print $res->status_line;

			exit 1;
		}

		#
		# decode_json() is provided by the JSON module.
		#
		my $data            = decode_json( $res->decoded_content() );
		my $client_id       = $data->{ id };
		my $client_username = $data->{ username };

		print "retrieved client id $client_id user name $client_username.\n";

		push @client_user_names, $client_username;
	}

	return @client_user_names;
}

#
# Get all client IDs for an asset in WHD using the hardware serial number.
#
# Returns an array of client IDs.
#
sub get_whd_asset_client_ids {

	my $data     = get_whd_asset_data();
	my $asset_id = $data->{ id };
	my $asset_no = $data->{ assetNumber };
	my @clients  = @{ $data->{ clients } };

	print "retrieved asset id $asset_id tag $asset_no serial number $hw_serial_no.\n";

	if ( @clients < 1 ) {

		print "asset id $asset_id tag $asset_no serial number $hw_serial_no has no clients.\n\n";
	}

	my @client_ids;

	foreach ( @clients ) {

		push @client_ids, $_->{ id };
	}

	return @client_ids;
}

#
# Get an asset from WHD using the hardware serial number.
#
# Returns a single asset array.
#
# If there is 0 or more than 1 asset(s) returned by the WHD API query, then
# exit with an error.
#
sub get_whd_asset_data {

	my $whd_serial_no = $_[ 0 ] || $hw_serial_no;
	my $is_try_again  = $_[ 1 ] || 0;

	my $url = URI->new( $whd_asset_url );

	$url->query_form(
		'username'  => $whd_api_user,
		'apiKey'    => $whd_api_key,
		'qualifier' => "( serialNumber = '${whd_serial_no}' )",
		'style'     => 'details'
	);

	my $ua = LWP::UserAgent->new();

	$ua->ssl_opts( SSL_ca_file => $cacert_pem );

	my $res = $ua->get( $url );

	if ( ! $res->is_success ) {

		print $res->status_line;

		exit 1;
	}

	#
	# decode_json() is provided by the JSON module.
	#
	my $data = decode_json( $res->decoded_content() );

	if ( @{ $data } < 1 ) {

		print "error: no asset for serial number $whd_serial_no.\n";

		if ( $is_try_again ) {

			print "\n";

			exit 1;
		}

		#
		# The barcode scanner adds an extra "S", so if we do not find
		# the asset, try again with a leading "S".
		#
		return get_whd_asset_data( "S$whd_serial_no", 1 );

	} elsif ( @{ $data } > 1 ) {

		print "error: more than one asset for serial number $whd_serial_no.\n\n";

		exit 1;
	}

	return @{ $data }[ 0 ];
}
