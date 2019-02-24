#!/bin/bash

AUTHOR="Ozan Kiratli"
VERSION="0.9"
EMAIL="ozankiratli@protonmail.com"

SCRIPTNAME=`basename "$0"`
HOMEDIR="/home/$USER"
NORDPATH="$HOMEDIR/build/nordvpn"
OVPNPATH="/etc/openvpn"
PORT="udp"
VPNNAME="NordVPN"
LOGINFILE=".nvpn.login"
FIRSTUSE=0

function checkflag {
	if [ "${1:0:1}" = "-" ] ; then
		echo "Error: Missing Argument after a flag!"
		quit1
	fi
}

function checkopenvpn {
	echo "Checking if OpenVPN is installed!"
	echo " "
	VOPN=`openvpn --version | head -1 | awk '{print $1 " " $2}'`
	if [ -z "$VOPN" ] ; then
		echo "OpenVPN is not installed!"
		installopenvpn
	else
		echo "OpenVPN is installed. $VOPN"
	fi
}

function downloadfiles {
	while true ; do
		echo "This process will try to download the config file"
		read -p "Do you want to continue? [y/N]" yn
		case $yn in
			[Yy]* )
				echo "Downloading files for server: $1"
				echo " "
				LINKUDP="https://downloads.nordcdn.com/configs/files/ovpn_legacy/servers/$1.nordvpn.com.udp1194.ovpn"
				LINKTCP="https://downloads.nordcdn.com/configs/files/ovpn_legacy/servers/$1.nordvpn.com.tcp443.ovpn"
				wget --spider $LINKUDP -o tmp
				EXISTS=`grep "Remote file exists" tmp`
				rm tmp
				if [ -z "$EXISTS" ] ; then
					echo "The link for UDP config file does not exist"
				else
					wget $LINKUDP -O $2/$1.nordvpn.com.udp1194.ovpn
				fi
				wget --spider $LINKTCP -o tmp
				EXISTS=`grep "Remote file exists" tmp`
				rm tmp
				if [ -z "$EXISTS" ] ; then
					echo "The link for TCP config file does not exist"
				else
					wget $LINKTCP -O $2/$1.nordvpn.com.tcp443.ovpn
				fi
				break
				;;
			N|n|"" )
				echo "Exiting downloader"
				break
				;;
			* )
				echo "Please enter y or n"
				;;
		esac
	done
}

function help {
		echo "NordVPN client on OpenVPN easy setup script"
		echo " "
		echo "$SCRIPTNAME -s <servername> [options [arguments] ] "
		echo " "
		echo "options:"
		echo "-h, --help			Display help (this message)"
		echo "-s <ServerName>			NordVPN server"
		echo "-d <ServerName>			Downloads config files for a particular server"
		echo "-p <PortType>			Port type TCP or UDP"
		echo "-N /path/to/NordVPNfiles		Defines path to downloaded openvpn files"
		echo "-C /path/to/openvpn		Path to OpenVPN configuration files in the system"
		echo "-n <VPNServiceName>		Name of the configuration filename without .ovpn or .conf"
		echo "--firstuse			Use this flag if you are setting up NordVPN client for the first time"
		echo "-l				Lists all available servers"
		echo "-l --country <CountryCode>	Lists servers of the chosen country. Use 2 letter country codes"
		echo "-l --port <PortType>		Lists servers of the chosen port type. TCP or UDP"
		echo "-l --country <CC> --port <PT>	Lists servers of the chosen country and port."
		echo "--checkserver <servername>	Shows if the server is available and available port types."
		echo "-u, --usage 			Correct usage options"
		echo "--updatefiles			Updates the files"
		echo "--start <VPNServiceName>		Starts service"
		echo "--stop <VPNServiceName>		Stops service"
		echo "--restart <VPNServiceName>	Restarts service"
		echo "--status <VPNServiceName>		Returns service status"
		echo "--enable <VPNServiceName>		Enables service"
		echo "--disable <VPNServiceName>	Disables service"
		echo " "
		echo "Be aware that -h, -l, -d, --checkserver, -u, --updatefiles, --start, --stop, --restart, -status, --enable, and --disable options will override other options, the first of these options will be processed, the others will be ignored."
		echo " "
		echo "Default options are:"
		echo "usage: $SCRIPTNAME -s <ServerName> [default=none] -p <PortType> [default=$PORT] -C <path/to/NordVPN> [default=$NORDPATH] -O <path/to/OpenVPN> [default=$OVPNPATH] -f <filename> [default=$VPNFILENAME]"
}

function installopenvpn {
	while true ; do
		read -p "Do you want to install OpenVPN? [y/N]" YesNo
		case $YesNo in
			[Yy]* )
				sudo apt install openvpn
				break
				;;
			N|n|"")
				echo "OpenVPN will not be installed."
				echo "Without OpenVPN the script cannot continue"
				exit 1
				;;
			*)
				echo "Select y or n"
				;;
		esac
	done
}

function maketitle {
	echo "NordVPN on OpenVPN Easy Setup Script  ver$VERSION"
	echo "	"
	echo "$SCRIPTNAME ver$VERSION"
	echo "	"
	echo "Coded by: $AUTHOR"
	echo "e-mail: $EMAIL"
	echo " "
	echo "This version of the script works only on Linux Systems"
	echo " "
	echo "Feel free to contact with any questions."
	echo "Enjoy!"
	echo " "
	echo " "
}

function quit1 {
	echo "For Correct Usage, Try: $SCRIPTNAME -u"
	echo "For Help, Try: $SCRIPTNAME -h"
	echo "Exiting script!"
	exit 1
}

function runsysctl {
	checkflag $2
	if [ -z "$2" ] ; then
		echo "VPN name is set to default!"
	else
		echo "VPN nameis set to $2"
		VPNNAME=$2
	fi
	echo "Running: sudo systemctl $1 openvpn@$VPNNAME.service"
	sudo systemctl $1 openvpn@$VPNNAME.service
	echo "Done!"
}

function restartVPN {
	OVPNPATH=$1
	VPNNAME=$2
	IPNOVPN=$3
	IP2BE=`grep "remote " $OVPNPATH/$VPNNAME.conf | awk '{print $2}'`
	echo "Checking IP settings..."
	IPCUR=`wget -T 5 -t 1 -qO- https://api.ipify.org`
	echo "Expected IP is	: $IP2BE"
	echo "Current IP is	: $IPCUR"

	for i in {1..3} ; do
		echo "Checking the configuration of the VPN service... Trial $i"
		echo "Restarting the VPN service..."
		sudo systemctl start openvpn@$VPNNAME.service
		echo "If no errors occurred, VPN service has been restarted!"
		echo "Checking IP settings..."
		IPCUR=`wget -T 5 -t 1 -qO- https://api.ipify.org`

		for j in {1..3} ; do
			IPCUR=`wget -T 5 -t 1 -qO- https://api.ipify.org`
			if  [ -z "$IPCUR" ] ; then
				echo "Warning: No IP is assigned at the moment!"
				echo "Trying to get IP"
				echo "Public IP is	: $IPCUR"
				echo "Expected IP is	: $IP2BE"
			elif  [ "$IPCUR" == "$IP2BE" ] ; then
				echo "IP settings are correct"
				echo "Script successfully changed the server to $1"
				echo "Public IP is	: $IPCUR"
				echo "Expected IP is	: $IP2BE"
				exit 1
			elif [ "$IPCUR" == "$IPNOVPN" ] ; then
				echo "Warning: IP is still the IP without VPN, your internet is not currently masked!"
				echo "Trying to get IP"
				echo "Public IP is	: $IPCUR"
				echo "Expected IP is	: $IP2BE"
			else
				break
			fi
			echo "Waiting 15 seconds to try again..."
			sleep 15s
		done
		echo "WARNING: Public IP: $IPCUR is not the same as Expected IP: $IP2BE"

		if [ -z "$IPCUR" ] ; then
			echo "There is no IP at the moment!"
		else
			echo "Current IP is: $IPCUR"
			while true ; do
				read -p "Do you want to keep the current IP? [y/N]  Warning: According to your IPTABLES configuration, you might lose internet connection!" YesNo
				case $YesNo in
					[Yy]* )
						echo "Expected IP was: $IP2BE"
						echo "Your IP has been changed to: $IPCUR"
						echo "Exiting script!"
						exit 1
						;;
					N|n|"")
						echo "This will try to restart the VPN service and try again"
						break
						;;
					*)
						echo "Select y or n"
						;;
				esac
			done
		fi
		if [ $i == 3 ] ; then
			break
		else
			echo "Stopping the VPN service..."
			sudo systemctl stop openvpn@$VPNNAME.service
			echo "Done!"
		fi
	done
}

function update {
	while true ; do
		echo "This process will first backup all files in $1/backup, then overwrite all the configuration files in $1."
		read -p "Do you want to update config files? [y/N]" yn
		case $yn in
			[Yy]* )
				echo "Updating files..."
				echo " "
				echo "Starting backup..."
				mkdir -p $1/backup
				wait
				mv $1/*.ovpn $1/backup/
				wait
				mv $1/*.zip $1/backup/
				wait
				echo "Backup finished!"
				echo " "
				echo "Downloading configuration files..."
				wget https://nordvpn.com/api/files/zip -O $1/config.zip
				wait
				echo "Unzipping the files..."
				unzip -q $1/config.zip -d $1
				wait
				echo " "
				echo "The server files are updated!"
				echo "The files are in $1!"
				break
				;;
			N|n|"" )
				echo "Exiting Updater!"
				break
				;;
			* )
				echo "Please enter y or n"
				;;
		esac
	done
}

function usage {
	echo "Correct Usage Instructions:"
	echo " "
	echo "Setting NordVPN:"
	echo "$SCRIPTNAME -s <ServerName> [default=none] -p <PortType> [default=$PORT] -C <path/to/NordVPN> [default=$NORDPATH] -O <path/to/OpenVPN> [default=$OVPNPATH] -f <filename> [default=$VPNFILENAME]"
	echo " "
	echo "For Help:"
	echo "$SCRIPTNAME -h or $SCRIPTNAME --help"
	echo " "
	echo "For Usage: (Displaying this list)"
	echo "$SCRIPTNAME -u or $SCRIPTNAME --usage"
	echo " "
	echo "For Listing Servers:"
	echo "$SCRIPTNAME -l [--country <2LetterCountryCode>] [--port <PortType>]"
	echo " "
	echo "For Checking if a Server file is present in the local machine:"
	echo "$SCRIPTNAME --checkserver <ServerName>"
	echo " "
	echo "For Updating Server files in the local machine:"
	echo "$SCRIPTNAME --updatefiles"
	echo " "
	echo "For Client Services:"
	echo "$SCRIPTNAME --enable/--disable/--start/--stop/--restart/--status <VPNServiceName>" 
}
maketitle

if [ -z "$1" ] ; then
	quit1
fi

while test $# -gt 0; do
case "$1" in
	-h|--help)
		help
		exit 0
		;;
	-s)
		shift
		if test $# -gt 0; then
			checkflag $1
			SERVER=$1
		else
			echo "No server specified!"
			quit1
		fi
		shift
		;;
	-p)
		shift
		if test $# -gt 0; then
			checkflag $1
			PT1="$1"
			PT=`echo "$PT1" | awk '{print tolower($0)}'`
			if [ "$PT" = "tcp" ] || [ "$PT" = "udp" ] ; then
				PORT=$PT
			else
				echo "The port type is not correct, use TCP or UDP"
				quit1
			fi
		else
			echo "No port specified!"
			quit1
		fi
		shift
		;;
	-C)
		shift
		if test $# -gt 0; then
			PATH1=`ls -ld $1 | awk '{print $9}'`
			checkflag $1
			if [ -z "$PATH1" ] ; then
				echo "Wrong PATH for OpenVPN configuration files!"
				quit1
			else
				OVPNPATH=$1
			fi
		else
			echo "No PATH specified for OpenVPN configuration files!"
			quit1
		fi
		shift
		;;
	-N)
		shift
		if test $# -gt 0; then
			PATH2=`ls -ld $1 | awk '{print $9}'`
			checkflag $1
			if [ -z "$PATH2" ] ; then
				echo "Wrong PATH for NordVPN configuration files!"
				quit1
			else
				NORDPATH=$1
			fi
		else
			echo "No PATH specified for NordVPN configuration files!"
			quit1
		fi
		shift
		;;
	-f)
		shift
		if test $# -gt 0; then
			checkflag $1
			VPNNAME=$1
		else
			echo "No filename specified!"
			quit1
		fi
		shift
		;;
	--firstuse)
		FIRSTUSE=1
		read -p "Enter name of login authorization file (Default name is: .nvpn.login )" lfile
		if [ -z "lfile" ] ; then
			LOGINFILE=$lfile
		fi
		FU="firstusetmp"
		read -p "Enter NordVPN username:" USERNAME
		read -p "Enter NordVPN password:" PASSWORD
		touch futmp
		echo "$USERNAME" >> futmp
		echo "$PASSWORD" >> futmp
		mv futmp $LOGINFILE
		sudo mv $LOGINFILE $NORDPATH
		shift
		;;
	-l)
		shift
		SEARCHSTRING="*"
		while test $# -gt 0; do
			case "$1" in
				--country)
					shift
					if test $# -gt 0; then
						checkflag $1
						CC="$1"
						CCD=`echo "$CC" | awk '{print tolower($0)}'`
						if [ ${#CCD} != 2 ] ; then
							echo "Two letter country code expected"
							echo "Try $SCRIPTNAME -h -l"
							quit1
						fi
						SEARCHSTRING="$CCD$SEARCHSTRING"
					else
						echo "Two letter country code expected"
						echo "Try $SCRIPTNAME -h -l"
						quit1
					fi
					shift
					;;
				--port)
					shift
					if [ -z "$1" ] ; then
						echo "Port type is not specified"
						echo "Try $SCRIPTNAME -h -l"
						quit1
					fi
					checkflag $1
					PRPT="$1"
					PRT=`echo "$PRPT" | awk '{print tolower($0)}'`
					if [ "$PRT" = "tcp" ] || [ "$PRT" = "udp" ] ; then
						SEARCHSTRING=$SEARCHSTRING$PRT"*"
					else
						echo "The port type is not correct, use TCP or UDP"
						echo "Try $SCRIPTNAME -h"
						quit1
					fi
					shift
					;;

				*)
					echo "Wrong option try: $SCRIPTNAME -h -l"
					quit1
					;;
			esac
		done

		ls $NORDPATH/$SEARCHSTRING | sed -e 's/\// /g' | awk '{print $NF}' | sed -e 's/\./ /g' | awk '{print $1 " " $4}' | more
		exit 1
		;;
	-d)
		shift
		if [ -z "$1" ] ; then
			echo "Servername is not specified"
			echo "Try $SCRIPTNAME -h"
			quit1
		fi
		downloadfiles $1 $NORDPATH
		exit 1
		;;
	--checkserver)
		shift
		if [ -z "$1" ] ; then
			echo "Server name is not specified"
			echo "Try $SCRIPTNAME -h"
			quit1
		fi
		checkflag $1
		SVN="$1"
		SVNM=`echo "$SVN" | awk '{print tolower($0)}'`
		SEARCHSTRING=$SVNM"*"

		ls $NORDPATH/$SEARCHSTRING | sed -e 's/\// /g' | awk '{print $NF}' | sed -e 's/\./ /g' | awk '{print $1 " " $4}' | more
		exit 1
		;;
	--updatefiles)
		update $NORDPATH
		exit 1
		;;
	-u|--usage)
		usage
		exit 1
		;;
	--start)
		shift
		runsysctl start $1
		exit 1
		;;
	--stop)
		shift
		runsysctl stop $1
		exit 1
		;;
	--restart)
		shift
		echo "Stopping VPN service..."
		runsysctl stop $1
		echo "Done!"
		sleep 2s
		IPNOVPN=`wget -T 5 -t 1 -qO- https://api.ipify.org`
		echo "IP without VPN is: $IPNOVPN"
		sleep 1s
		restartVPN $OVPNPATH $VPNNAME $IPNOVPN
		exit 1
		;;
	--status)
		shift
		runsysctl status $1
		exit 1
		;;
	--disable)
		shift
		runsysctl stop $1
		wait
		runsysctl disable $1
		exit 1
		;;
	--enable)
		shift
		runsysctl enable $1
		wait
		runsysctl start $1
		exit 1
		;;
	*)
		echo "Option $1 is not available."
		quit1
		;;
	esac
done

if [ -z "$SERVER" ] ; then
	echo "Server name is not defined!"
	echo "Use -s flag with a proper server name"
	quit1
fi

VPNFILE="$VPNNAME.conf"
SERVERFILE=`ls $NORDPATH/$SERVER.*.$PORT*`
echo "Login: $LOGINFILE"
echo "Server: $SERVERFILE"

if [ -z "$SERVERFILE" ] ; then
	while true ; do
		read -p "Wrong server name or missing server file. Do you want to update config files? [y/N]" yn
		case $yn in
			[Yy]* )
			downloadfiles $SERVER $NORDPATH
			echo "Trying again!"
				SERVERFILE=`ls $NORDPATH/$SERVER.*.$PORT*`
				if [ -z "$SERVERFILE" ] ; then
					echo "Still, wrong server name or missing server file! Trying to update all files!"
					update $NORDPATH
					SERVERFILE=`ls $NORDPATH/$SERVER.*.$PORT*`
					if [ -z "$SERVERFILE" ] ; then
						echo "Still, wrong server name or missing server file! Trying to update all files!"
						exit 1
					fi
				fi
				break
				;;
			N|n|"" )
				echo "Wrong server name or missing server file, check again"
				quit1
				;;
			* )
				echo "Please enter y or n"
		esac
	done
fi

checkopenvpn

echo "Backing up the old configuration file to $OVPNPATH/$VPNFILE.save"
sudo cp $OVPNPATH/$VPNFILE $OVPNPATH/$VPNFILE.save
sudo cp $SERVERFILE $OVPNPATH/tmp.conf
sudo sed -i "/auth-user-pass/c\auth-user-pass $OVPNPATH/$LOGINFILE" $OVPNPATH/tmp.conf

NULL=`grep -E "$LOGINFILE" $OVPNPATH/tmp.conf`
if [ -z "$NULL" ] ; then
	echo "Unsuccessful attempt to add login info"
	quit1
fi

IPATM=`wget -T 5 -t 1 -qO- https://api.ipify.org`
echo "IP at the moment is: $IPATM"
IP2BE=`grep "remote " $OVPNPATH/tmp.conf | awk '{print $2}'`
echo "IP of destination VPN is: $IP2BE"

echo "Stopping VPN service..."
sudo systemctl stop openvpn@$VPNNAME.service
echo "Done!"
sleep 2s
IPNOVPN=`wget -T 5 -t 1 -qO- https://api.ipify.org`
echo "IP without VPN is: $IPNOVPN"
sleep 2s

if [ $FIRSTUSE == 1 ] ; then
	sudo mv $OVPNPATH/tmp.conf $OVPNPATH/$VPNFILE
	echo "Enabling $VPNNAME ..."
	sudo systemctl enable openvpn@$VPNNAME.service
	wait
	echo "Starting $VPNNAME ..."
	sudo systemctl start openvpn@$VPNNAME.service
	wait
	echo "$VPNNAME has been started!"
elif [ "$IPATM" = "$IP2BE" ] ; then
	echo "You are using the same server. No need to change!"
	echo "Current IP: $IPATM"
	exit 1
else
	echo "Replacing configuration file with the new file..."
	sudo mv $OVPNPATH/tmp.conf $OVPNPATH/$VPNFILE
	echo "Done!"
	sleep 1s
fi

restartVPN $OVPNPATH $VPNNAME $IPNOVPN

IPCUR=`wget -T 5 -t 1 -qO- https://api.ipify.org`
if  [ "$IPCUR" != "$IP2BE" ] ; then
	echo "IP could not be set correctly"
	echo "Script failed to change the server to $SERVER"
	echo "Public IP is: $IPCUR"
	exit 1
fi

echo "Unknown error! OMG! This shouldn't be happening! Contact me at $EMAIL!"
