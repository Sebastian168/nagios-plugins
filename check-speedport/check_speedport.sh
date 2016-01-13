#!/bin/bash
#
# Author:	Matthias Krause - https://github.com/mkrsn/
# Version:	0.3.1
# License:	GPL
# Comment:	This Script gets the Report from thw old "Online Control" interface of the Speedport
#		and processes its information.
# Usage:	check_speedport.sh <ip/fqdn>
# Changes:	0.1 - 2010-10-10 - Initial Release - W722V tested
#		0.2 - 2010-11-02 - Changing parts of the loop. Using regex now
#		0.3 - 2010-11-17 - Extending the Output in case of Problems
#		0.3.1 - 2016-01-14 - Translating the Text to english


#########################################
#		VARIABLES		#
#########################################

# Parameters
Host="${1}";

# Tools
Curl="/usr/bin/curl";			# contains curl
Cut="/usr/bin/cut";			# contains cut
Echo="/bin/echo";			# contains echo
Grep="/bin/grep";			# contains grep
Sed="/bin/sed";				# contains sed

# Information
DslAvail="";				# Contains the current status of synchronisation
OcStat="";				# Contains the complete Report from the OnlineControl interface
Var="";					# In the loop, this variable contains just one Row / Key-Value Pair
WanAvail="";				# Contains the Status of blocked connections
WanConnected="";			# Contains the Status of the WAN-connection
WanGateway="";				# Contains the WAN default gateway
WanIp="";				# Contains the current IP-address
WanSubnetmask="";			# Contains the current Subnetmask


#########################################
#	SCRIPT - EXECUTION		#
#########################################


# Get status from device
OcStat="$(${Curl} -k https://${Host}/hcti_status_ocontrol.htm 2> /dev/null)";


# Check curls exitcode
case ${?} in
	2)
		${Echo} "Failed to initialize";
		exit 2;
	;;

	6)
		${Echo} "Couldn't resolve host. The given remote host was not resolved";
		exit 3;
	;;

	7)
		${Echo} "Failed to connect to host";
		exit 2;
	;;

	35)
		${Echo} "SSL connect error. The SSL handshaking failed";
		exit 3;
	;;

	43)
		${Echo} "Internal error. A function was called with a bad parameter";
		exit 3;
	;;
esac


# Loop the whole Report and pick the needed information
for Var in ${OcStat}; do
	if [[ ${Var} == bDSLAvail=?\; ]]; then
		DslAvail=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi

	if [[ ${Var} == bWanAvail=?\; ]]; then
		WanAvail=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi

	if [[ ${Var} == bWanConnected=?\; ]]; then
		WanConnected=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi



	if [[ ${Var} == wan_gateway=*\; ]]; then
		WanGateway=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi

	if [[ ${Var} == wan_ip=*\; ]]; then
		WanIp=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi

	if [[ ${Var} == wan_subnet_mask=*\; ]]; then
		WanSubnetmask=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi
done


# Checks the current status and exits with the appropriate exitcode
if [ ${DslAvail} == 1 ] && [ ${WanAvail} == 1 ] && [ ${WanConnected} == 1 ]
	then
		${Echo} "(V)DSL UP - IP=${WanIp}, SNM=${WanSubnetmask}, DGW=${WanGateway}";
		${Echo} "(V)DSL-Sync=${DslAvail}, Web-Release=${WanAvail}, (V)DSL-Connection=${WanConnected}";
		exit 0;
	else
		${Echo} "(V)DSL-Sync=${DslAvail}, Web-Release=${WanAvail}, (V)DSL-Connection=${WanConnected}";
		${Echo} "(V)DSL DOWN - IP=${WanIp}, SNM=${WanSubnetmask}, DGW=${WanGateway}";
		exit 2;
fi

# vim: ai ts=8 noet nosi ft=sh
