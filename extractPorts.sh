#!/bin/bash

# Reset
CLF='\033[0m'       # Text Reset

# Regular Colors
BLK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GRN='\033[0;32m'        # Green
YLW='\033[0;33m'       # Yellow
BlU='\033[0;34m'         # Blue
PPL='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHT='\033[0;37m'        # White


#Exit function
ctrl_c(){
	/usr/bin/echo -e "\n\n${RED}[+]${CLF} Exiting...\n"
	exit 1
}

# Ctrl+C
trap ctrl_c INT



#Help msg
usage(){
	/usr/bin/echo -e "${CYAN}[+]${CLF} Help mode. Usage example:\n"
	/usr/bin/echo -e "\textractPorts <source_file_name> <dest_file_name (OPTIONAL)>\n"
	return 0
}


#Extracts all ports
get_ports(){
	#Useless data + ports info
	all_data=$(/usr/bin/grep "Ports:" $1)

	#Just ports info
	ports_data=$(/usr/bin/echo $all_data | /usr/bin/awk '{ print $2 }' FS='Ports:')

	#Number of ports
	n_ports=$(/usr/bin/echo $ports_data | /usr/bin/awk -F',' '{ print NF }')

	#Ports accumulator
	all_acc_ports=$(/usr/bin/echo $(/usr/bin/echo $ports_data | /usr/bin/awk -F',' '{ print $1 }' | /usr/bin/awk -F'/' '{ print $1 }' | /usr/bin/tr -d '\n'))

	#Next port to analyze
	new_port=""

	/usr/bin/echo -e "\n\t${PPL}[+]${CLF} $n_ports ports founded.\n"
	/usr/bin/echo -e "${CYAN}[+]${CLF} Extracting data..."

	for i in $(seq 2 $n_ports);
	do
		new_port=$(/usr/bin/echo $(/usr/bin/echo $ports_data | /usr/bin/awk -F',' '{ print $'$i' }' | /usr/bin/awk -F'/' '{ print $1 }' | /usr/bin/tr -d '\n'))
		all_acc_ports=$(/usr/bin/echo "$all_acc_ports,$new_port")
	done

	if [ $# == 2 ]; then
		create_report_file $2 $all_acc_ports
	fi

	/usr/bin/echo -e "${CYAN}[+]${CLF} Copying to clipboard..."
	(/usr/bin/echo -n $all_acc_ports | /usr/bin/xclip -sel clip) 2>/dev/null
	/usr/bin/echo -e "${PPL}[+]${CLF} Ports discovered:\n"

	/usr/bin/echo -e "\t$all_acc_ports"
	/usr/bin/echo
	return 0
}


#Saves the output in a file
create_report_file(){
	if [ -f $1 ]; then
		/usr/bin/echo -n -e "\n${YLW}[WARNING]${CLF} This file already exists, do you want to overwrite it?[y/n]: "
		read usr_input

		if [ $usr_input == "n" ]; then
			return 1
		fi
	fi
	/usr/bin/echo -e "${CYAN}[+]${CLF} Saving data..."
	(/usr/bin/echo -e "${PPL}[+]${CLF} Ports discovered:\n" > $1) 2> /dev/null

	if [ $? == 1 ]; then
		/usr/bin/echo -e "${RED}[ERROR]${CLF} Error writing to file. Make sure you have write permissions."
		return 1
	fi
	/usr/bin/echo $2 >> $1

	/usr/bin/echo -e "${PPL}[+]${CLF} Data saved."
	return 0
}


if [ $# == 0 ] || [ $# -gt 2 ] || [ $1 == "-h" ] || [ $1 == "--help" ]; then
	usage
else
	/usr/bin/echo -e "${CYAN}[+]${CLF} Reading file..."
	if [ -f  $1 ]; then

		#Check if its an nmap -oG file
		/usr/bin/echo -e "${CYAN}[+]${CLF} Checking nmap headers..."

		first_line=$(/usr/bin/head -n 1 $1 | /usr/bin/awk '{ print $2 };')
		last_line=$(/usr/bin/tail -n 1 $1 | /usr/bin/awk '{ print $2 };')

		#Strings length
		f_s=${#first_line}
		l_s=${#last_line}

		#Check if the file has Nmap structure looking for key words
		if [ $f_s -gt 0 ] && [ $l_s -gt 0 ] && [ $first_line == $last_line ] && [ $first_line == "Nmap" ]; then
			/usr/bin/echo -e "${PPL}[+]${CLF} Nmap file founded:"

			get_ports $1 $2

		else
			/usr/bin/echo -e "${RED}[ERROR]${CLF} Error validating nmap structure. Make sure to use the -oG Nmap option and try again.\n"
			exit 1
		fi
	else
		/usr/bin/echo -e "${RED}[ERROR]${CLF} File not found.\n"
		exit 1
	fi
fi

exit 0
