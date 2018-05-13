# NordVPNonOVPN
Easy Setup for NordVPN using OpenVPN on Linux OS

INSTALLATION:

 

Download the bash script file, and set permissions

$ git clone ..

$ sudo cp /path/NordVPNSetup.sh /usr/local/bin 

$ sudo chmod +x /usr/local/bin  

 
 

RUNNING:
 
NordVPNSetup.sh -s <servername> [options [arguments] ] 
 
options:

-h, --help			Display help (this message)

-s <ServerName>			NordVPN server

-p <PortType>			Port type TCP or UDP

-N /path/to/NordVPNfiles		Defines path to downloaded openvpn files

-C /path/to/openvpn		Path to OpenVPN configuration files in the system

-n <VPNServiceName>		Name of the configuration filename without .ovpn or .conf

--firstuse			Use this flag if you are setting up NordVPN client for the first time

-l				Lists all available servers

-l --country <CountryCode>	Lists servers of the chosen country. Use 2 letter country codes

-l --port <PortType>		Lists servers of the chosen port type. TCP or UDP

-l --country <CC> --port <PT>	Lists servers of the chosen country and port.

--checkserver <servername>	Shows if the server is available and available port types.

-u, --usage 			Correct usage options

--updatefiles			Updates the files

--start <VPNServiceName>		Starts service

--stop <VPNServiceName>		Stops service

--restart <VPNServiceName>	Restarts service

--status <VPNServiceName>		Returns service status

--enable <VPNServiceName>		Enables service

--disable <VPNServiceName>	Disables service

 

Be aware that -h, -l, --checkserver, -u, --updatefiles, --start, --stop, --restart, -status, --enable, and --disable options will override other options, the first of these options will be processed, the others will be ignored.

 

Default options are:

NordVPNSetup.sh -s <ServerName> [default=none] -p <PortType> [default=udp] -C <path/to/NordVPN> [default=/home/romulan/build/nordvpn] -O <path/to/OpenVPN> [default=/etc/openvpn] -f <filename> [default=]

 

USAGE SUGGESTIONS:

 

Setting NordVPN:

NordVPNSetup.sh -s <ServerName> [default=none] -p <PortType> [default=udp] -C <path/to/NordVPN> [default=/home/romulan/build/nordvpn] -O <path/to/OpenVPN> [default=/etc/openvpn] -f <filename> [default=]
 
 

For Help:

NordVPNSetup.sh -h or NordVPNSetup.sh --help

 

For Usage: (Displaying this list)

NordVPNSetup.sh -u or NordVPNSetup.sh --usage
 
 

For Listing Servers:

NordVPNSetup.sh -l [--country <2LetterCountryCode>] [--port <PortType>]

 

For Checking if a Server file is present in the local machine:

NordVPNSetup.sh --checkserver <ServerName>

 

For Updating Server files in the local machine:

NordVPNSetup.sh --updatefiles

 

For Client Services:

NordVPNSetup.sh --enable/--disable/--start/--stop/--restart/--status <VPNServiceName>
