#!/bin/bash
#
# Author:	Matthias Krause
# Contact:	matthias.krause@hotmail.de
# Version:	0.3
# License:	GPL
# Comment:	Dieses Script fragt die "Online Control" Schnittstelle des Speedports ab
#		und verarbeitet die Informationen entsprechend.
# Usage:	check_speedport.sh <ip/fqdn>
# Changes:	0.1 - 10.10.2010 - Initial Release - W722V tested
#		0.2 - 02.11.2010 - Anpassung von Bedingungen in for Schleife. Verwendung von Regex.
#		0.3 - 17.11.2010 - Erweiterung der Ausgaben bei Verbindungsfehlern.


#########################################
#		VARIABLEN		#
#########################################

# Parameters
Host="${1}";

# Tools
Curl="/usr/bin/curl";			# Beinhaltet das Werkzeug curl
Cut="/usr/bin/cut";			# Beinhaltet das Werkzeug cut
Echo="/bin/echo";			# Beinhaltet das Werkzeug echo
Grep="/bin/grep";			# Beinhaltet das Werkzeug grep
Sed="/bin/sed";				# Beinhaltet das Werkzeug sed

# Information
DslAvail="";				# Beinhaltet die Info, ob eine Synchronisierung der Leitung besteht
OcStat="";				# Beinhaltet den gesamten Status Report der OnlineControl Schnittstelle
Var="";					# Beinhaltet beim schleifendurchlauf jeweils eine Zeile
WanAvail="";				# Beinhaltet die Info, ob Verbindungen gesperrt sind
WanConnected="";			# Beinhaltet die Info, ob eine Internet Verbindung besteht
WanGateway="";				# Beinhaltet das entsprechende Default gateway
WanIp="";				# Beinhaltet die aktuelle WAN IP
WanSubnetmask="";			# Beinhaltet die entsprechende WAN Subnetmask


#########################################
#	SCRIPT - Durchführung		#
#########################################


# Läd den Bericht vom Speedport und schreibt ihn in die Variable Status.
OcStat="$(${Curl} -k https://${Host}/hcti_status_ocontrol.htm 2> /dev/null)";


# Prüft ob curl sauber gearbeitet hat.
case ${?} in
	2)	# Failed to initialize.
		${Echo} "Failed to initialize";
		exit 2;
	;;

	6)	# Couldn't resolve host. The given remote host was not resolved.
		${Echo} "Couldn't resolve host. The given remote host was not resolved";
		exit 3;
	;;

	7)	# Failed to connect to host.
		${Echo} "Failed to connect to host";
		exit 2;
	;;

	35)	# SSL connect error. The SSL handshaking failed.
		${Echo} "SSL connect error. The SSL handshaking failed";
		exit 3;
	;;

	43)	# Internal error. A function was called with a bad parameter.
		${Echo} "Internal error. A function was called with a bad parameter";
		exit 3;
	;;
esac


for Var in ${OcStat}; do

	# Bestückt die Variable DslAvail mit der entsprechenden Information
	if [[ ${Var} == bDSLAvail=?\; ]]; then
		DslAvail=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi

	# Bestückt die Variable WanAvail mit der entsprechenden Information
	if [[ ${Var} == bWanAvail=?\; ]]; then
		WanAvail=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi

	# Bestückt die Variable WanConnected mit der entsprechenden Information
	if [[ ${Var} == bWanConnected=?\; ]]; then
		WanConnected=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/\;//);
	fi



	# Bestückt die Variable WanGateway mit der entsprechenden Information
	if [[ ${Var} == wan_gateway=*\; ]]; then
		WanGateway=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi

	# Bestückt die Variable Wanip mit der entsprechenden Information
	if [[ ${Var} == wan_ip=*\; ]]; then
		WanIp=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi

	# Bestückt die Variable WanSubnetmask mit der entsprechenden Information
	if [[ ${Var} == wan_subnet_mask=*\; ]]; then
		WanSubnetmask=$(${Echo} "${Var}" | ${Cut} -d "=" -f 2 | ${Sed} s/[\"\;]//g);
	fi
done


# Prüft den Status des Speedports und beendet sich mit entsprechenden Code.
if [ ${DslAvail} == 1 ] && [ ${WanAvail} == 1 ] && [ ${WanConnected} == 1 ]
	then
		${Echo} "(V)DSL UP - IP=${WanIp}, SNM=${WanSubnetmask},  DGW=${WanGateway}";
		${Echo} "(V)DSL-Sync=${DslAvail}, Web-Freigabe=${WanAvail}, DSL-Verbindung=${WanConnected}";
		exit 0;
	else
		${Echo} "(V)DSL-Sync=${DslAvail}, Web-Freigabe=${WanAvail}, DSL-Verbindung=${WanConnected}";
		${Echo} "(V)DSL DOWN - IP=${WanIp}, SNM=${WanSubnetmask}, DGW=${WanGateway}";
		exit 2;
fi
