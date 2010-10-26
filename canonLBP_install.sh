#!/bin/bash
################################################################################
# This script will help you install Canon CAPT Printer Driver 2.00 for         #
# Debian-based Linux systems using the 32bit or 64bit OS architecture.         #
#                                                                              #
# @author Radu Cotescu                                                         #
# @version 2.2                                                                 #
#                                                                              #
# For more details please visit:                                               #
#   http://radu.cotescu.com/?p=1194                                            #
################################################################################
param1="$1"
param2="$2"
param_no="$#"
args=$@

WORKSPACE="`dirname $0`/DEBS"
PRINTER_MODEL=""
PRINTER_SMODEL=""
ARCH=""
IP_REGEX="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
IP=""

models="LBP-1120 LBP-1210 LBP2900 LBP3000 LBP3010 LBP3018 LBP3050 LBP3100
LBP3108 LBP3150 LBP3200 LBP3210 LBP3250 LBP3300 LBP3310 LBP3500 LBP5000 LBP5050
LBP5100 LBP5300 LBP6300dn LBP7200C LBP9100Cdn"

usage_message="This script will help you install Canon CAPT Printer Driver \
2.00 for Debian-based Linux systems using the 64-bit OS architecture.\n"

options="PRINTER_MODEL can be any of the following:\n$models\n\n\
If an IP is supplied the printer will be accessed from the network at that address.\
 This setting is valid only for printers that support network printing."

display_usage() {
	echo -e "Usage: ./`basename $0` PRINTER_MODEL [IP]\n"
	echo -e $usage_message | fold -s
	echo -e $options | fold -s
}

check_superuser() {
	if [[ $USER != "root" ]]; then
		echo "This script must be run with superuser privileges!"
		display_usage
		exit 1
	fi
}

check_args() {
	if [[ $param_no -eq 1 ]]; then
		case $param1 in
			"-h" | "--help")
				display_usage
				exit 0
			;;
			*)
			for model in $models; do
				if [[ $param1 == $model ]]; then
					PRINTER_MODEL=$param1
					break;
				fi
			done
			check_printer_model
		esac
	elif [[ $param_no -eq 2 ]]; then
		for model in $models; do
			if [[ $param1 == $model ]]; then
				PRINTER_MODEL=$param1
				break;
			fi
		done
		check_printer_model
		IP=`echo $param2 | egrep -e "$IP_REGEX"`
		if [[ -z $IP ]]; then
			echo "Invalid IP!"
			exit 1
		fi
	else
		echo "Wrong parameter number!"
		display_usage
		exit 1
	fi
}

check_printer_model() {
	if [[ -z $PRINTER_MODEL ]]; then
		echo -e "Error: Unkown printer model!\n"
		display_usage
		exit 1
	fi
	case $PRINTER_MODEL in
	"LBP3100" | "LBP3108" | "LBP3150")
		PRINTER_SMODEL="LBP3150"
	;;
	"LBP3010" | "LBP3018" | "LBP3050")
		PRINTER_SMODEL="LBP3050"
	;;
	"LBP-1210")
		PRINTER_SMODEL="LBP1210"
	;;
	"LBP-1120")
		PRINTER_SMODEL="LBP1120"
	;;
	"LBP6300dn")
		PRINTER_SMODEL="LBP6300"
	;;
	"LBP9100Cdn")
		PRINTER_SMODEL="LBP9100C"
	;;
	*)
		PRINTER_SMODEL=$PRINTER_MODEL
	esac
}

packageError() {
	if [[ $1 -ne 0 ]]; then
		echo "I am unable to install the before mentioned package..."
		echo "Please install the required package and rerun the script..."
		exit 1
	fi
}

check_requirements_for_release() {
	release="`lsb_release -r | awk '{ print $2 }'`"
	lib=6
	if [[ "$release" == "9.10" ]]; then
		lib=5
	fi
	check_lib=`dpkg-query -W -f='${Status} ${Version}\n' libstdc++${lib} 2> /dev/null | egrep "^install"`
	if [[ -z $check_lib ]]; then
		echo "Installing libstdc++${lib} package..."
		apt-get -y install libstdc++${lib}
		packageError $?
	else echo "You do have the libstdc++${lib} package..."
	fi
	if [[ "$release" > "10" ]]; then
		cupsys2="cupsys_1.4.3-1ubuntu1.2_all.deb"
		if [[ -e $WORKSPACE/$cupsys2 ]]; then
			dpkg -i $WORKSPACE/$cupsys2
			else
			echo "$cupsys2 is missing from $WORKSPACE folder!"
			exit 1
		fi
	else #this means we run 9.10 (9.04 is not supported any more)
		libcups="libcupsys2_1.3.9-17ubuntu3.7_all.deb"
		if [[ -e $WORKSPACE/$libcups ]]; then
			dpkg -i $WORKSPACE/$libcups
		else
			echo "$libcups is missing from $WORKSPACE folder!"
			exit 1
		fi
	fi
}

install_driver() {
	machine=`uname -m`
	if [[ $machine == "x86_64" ]]; then
		ARCH="amd64"
	else
		ARCH="i386"
	fi
	cndrv_common="cndrvcups-common_2.00-1_${ARCH}.deb"
	cndrv_capt="cndrvcups-capt_2.00-1_${ARCH}.deb"
	echo "Installing driver for model: $PRINTER_MODEL"
	echo "using file: CNCUPS${PRINTER_SMODEL}CAPTK.ppd"
	echo "Installing packages..."
	check_requirements_for_release
	if [[ -e $WORKSPACE/$ARCH/$cndrv_common ]]; then
		dpkg -i $WORKSPACE/$ARCH/$cndrv_common
	else
		echo "$cndrv_common is missing from $WORKSPACE/$ARCH folder!"
		exit 1
	fi
	if [[ -e $WORKSPACE/$ARCH/$cndrv_capt ]]; then
		dpkg -i $WORKSPACE/$ARCH/$cndrv_capt
	else
		echo "$cndrv_capt is missing from $WORKSPACE/$ARCH folder!"
		exit 1
	fi
	echo "Modifying the default /etc/init.d/ccpd file..."
	cp -f $WORKSPACE/ccpd /etc/init.d/
	chmod a+x /etc/init.d/ccpd
	echo "Restarting CUPS..."
	/etc/init.d/cups restart
	echo "Setting the printer for CUPS..."
	/usr/sbin/lpadmin -p $PRINTER_MODEL -P /usr/share/cups/model/CNCUPS${PRINTER_SMODEL}CAPTK.ppd -v ccp://localhost:59687 -E
	echo "Setting the printer for CAPT..."
	if [[ -z $IP ]]; then
		/usr/sbin/ccpdadmin -p $PRINTER_MODEL -o /dev/usb/lp0
	else
		/usr/sbin/ccpdadmin -p $PRINTER_MODEL -o "net:$IP"
	fi
	echo "Setting CAPT to boot with the system..."
	update-rc.d ccpd defaults 50
	echo "Starting ccpd..."
	/etc/init.d/ccpd start
	sleep 2
	echo "Checking status:"
	/etc/init.d/ccpd status
	echo -e "\nPower on your printer! :)"
	echo "Go to System - Administration - Printing and do the following:"
	echo "  1. disable $PRINTER_MODEL-2 but do not delete it since Ubuntu will recreate it automatically;"
	echo "  2. set $PRINTER_MODEL as your default printer;"
	echo "  3. reboot your machine and print a test page."
}

exit_message() {
	echo -e "Script author: \n\tRadu Cotescu"
	echo -e "\thttp://radu.cotescu.com"
}

check_superuser
check_args
install_driver
exit_message
exit 0

