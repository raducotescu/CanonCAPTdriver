#!/bin/bash
################################################################################
# This script will help you install Canon CAPT Printer Driver 1.90 for         #
# Debian-based Linux systems using the 64-bit OS architecture.                 #
#                                                                              #
# @author Radu Cotescu                                                         #
# @version 1.0                                                                 #
################################################################################
param="$1"
param_no="$#"
args=$@

WORKSPACE="Canon_LBP_driver"
libstdc="libstdc++5_3.3.6-17ubuntu1_amd64.deb"
cndrv_common="cndrvcups-common_1.90-1_amd64.deb"
cndrv_capt="cndrvcups-capt_1.90-1_amd64.deb"
PRINTER_MODEL=""
PRINTER_SMODEL=""

models="LBP-1120 LBP-1210 LBP2900 LBP3000 LBP3010 LBP3018 LBP3050 LBP3100
LBP3108 LBP3150 LBP3200 LBP3210 LBP3250 LBP3300 LBP3310 LBP3500 LBP5000 LBP5050
LBP5100 LBP5300 LBP7200C"

usage_message="This script will help you install Canon CAPT Printer Driver \
1.90 for Debian-based Linux systems using the 64-bit OS architecture.\n"

options="PRINTER_MODEL can be any of the following:\n$models"

display_usage() {
	echo "Usage: ./`basename $0` PRINTER_MODEL"
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
	if [[ $param_no -ne 1 ]]; then
		display_usage
		exit 1
	fi 
	case $param in
		"-h" | "--help")
			display_usage
			exit 0
		;;
		*)
			for model in $models; do
				if [[ $param == $model ]]; then
					PRINTER_MODEL=$param
					break;
				fi
			done
	esac
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
	*)
		PRINTER_SMODEL=$PRINTER_MODEL
	esac
}

wget_check() {
	if [[ $? -ne 0 ]]; then
		echo "Unable to get requested file..."
		exit 1
	fi
}

install_driver() {
	echo "Creating `pwd`/$WORKSPACE folder..."
	mkdir $WORKSPACE
	echo "Downloading needed packages and files..."
	wget http://codebin.cotescu.com/canon/lbp_driver/$libstdc -O $WORKSPACE/$libstdc
	wget_check
	wget http://codebin.cotescu.com/canon/lbp_driver/$cndrv_common -O $WORKSPACE/$cndrv_common
	wget_check
	wget http://codebin.cotescu.com/canon/lbp_driver/$cndrv_capt -O $WORKSPACE/$cndrv_capt
	wget_check
	wget http://codebin.cotescu.com/canon/lbp_driver/ccpd -O $WORKSPACE/ccpd
	wget_check
	echo "Installing packages..."
	dpkg -i $WORKSPACE/$libstdc
	dpkg -i $WORKSPACE/$cndrv_common
	dpkg -i $WORKSPACE/$cndrv_capt
	echo "Modifying the default /etc/init.d/ccpd file..."
	cp -f $WORKSPACE/ccpd /etc/init.d/
	chmod a+x /etc/init.d/ccpd
	echo "Restarting CUPS..."
	/etc/init.d/cups restart
	echo "Setting the printer for CUPS..."
	/usr/sbin/lpadmin -p $PRINTER_MODEL -P /usr/share/cups/model/CNCUPS${PRINTER_SMODEL}CAPTK.ppd -v ccp:/var/ccpd/fifo0 -E
	echo "Setting the printer for CUPS..."
	/usr/sbin/ccpdadmin -p $PRINTER_MODEL -o /dev/usb/lp0
	echo "Setting CAPT to boot with the system..."
	update-rc.d ccpd defaults 50
	echo -e "\nPower on your printer! :)"
	echo "Go to System - Administration - Printing and do the following:"
	echo "  1. disable $PRINTER_MODEL-2 but do not delete it since Ubuntu will recreate it automatically;"
	echo "  2. set $PRINTER_MODEL as your default printer;"
	echo "  3. *restart* your machine and print a test page."
}

clean() {
	rm -rf $WORKSPACE
	echo -e "Script author: \n\tRadu Cotescu"
	echo -e "\thttp://radu.cotescu.com"
}

check_superuser
check_args
check_printer_model
echo "Installing driver for model: $PRINTER_MODEL"
echo "using file: CNCUPS${PRINTER_SMODEL}CAPTK.ppd"
install_driver
clean
exit 0

