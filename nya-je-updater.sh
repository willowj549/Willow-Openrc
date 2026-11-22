#!/bin/bash

# $dir variable, for the log
dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Help Text
Help() {
   # Display Help
   echo -e "\e[1mnya.je DDNS Updater\e[0m"
   echo
   echo -e "Syntax: nya-je-updater -a API-KEY -d DOMAIN -u [-h|-q|-i]"
   echo -e "Options:"
   echo -e "\e[1m-i\e[0m   Interactive Mode."
   echo -e "\e[1m-a\e[0m   Specify API key."
   echo -e "\e[1m-d\e[0m   Specify domain. (minus the .nya.je)"
   echo -e "\e[1m-u\e[0m   Update DDNS."
   echo -e "\e[1m-q\e[0m   Print Queries."
   echo -e "\e[1m-p\e[0m   Print Public IP Addresses."
   echo -e "\e[1m-h\e[0m   Print this Help."
   echo
}

if [ $# -eq 0 ];
then
    Help
    exit 1
fi

# Test Network Connection
Nettest() {
	echo -e '\n\e[1mChecking Network...\n\e[0m'
	if ping -c 1 1.1.1.1 > /dev/null; then
	  echo -e "\e[1;36mNetwork Good\e[0m\n"
	else
	  echo -e "\e[1;91mNetwork Bad\e[0m\n" && exit 1
	fi
	if nslookup google.com > /dev/null; then
	  echo -e "\e[1;36mDNS Good\e[0m\n"
	else
	  echo -e "\e[1;91mDNS Bad\e[0m\n" && exit 1
	fi
}

# Get Public IPs
Ipget() {
	ip=$(curl -4 -s https://v4.i-p.show/?plain=true)
	ipv6=$(curl -6 -s https://v6.i-p.show/?plain=true)
}

# Check Domains Current IP
Nsget() {
	cip=$(nslookup $domain.nya.je | grep -E "Address: \b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
	cipv6=$(nslookup $domain.nya.je | grep -E "Address: (::)?[0-9a-fA-F]{1,4}(::?[0-9a-fA-F]{1,4}){1,7}(::)?" | grep -oE "(::)?[0-9a-fA-F]{1,4}(::?[0-9a-fA-F]{1,4}){1,7}(::)?")
}

# Check API & Domain Name Variables
Varcheck() {
if [ "$api" = "" ]; then
       	echo -e "\e[1;91mPlease Specify API Key!!!!\e[0m\n" && exit 1
fi
if [ "$domain" = "" ]; then
        echo -e	"\e[1;91mPlease	Specify	Domain Name!!!!\e[0m\n" && exit 1
fi
}

# -p Option, Print Public IP Addresses
IP() {
	Nettest

	echo -e "\n\e[1mGetting IP Addresses...\n\e[0m"

	Ipget

	if [ "$ip" != "" ]; then
	echo -e "\e[0mPublic IPv4 Address: \e[1;36m$ip"
	fi

	if [ "$ipv6" != "" ]; then
	echo -e "\e[0mPublic IPv6 Address: \e[1;36m$ipv6"
	fi
}

# -i Option, Interactive
Interactive() {
echo -e "\n\e[1mnya.je DDNS updater\n\e[0m"

while true; do
	read -p $'\e[1mEnter your API key:\e[0m ' api 
  if [ -z "$api" ]; then
	echo -e "\e[1;91mPlease Specify API Key!!!!\e[0m\n"
  else
	break
  fi
done
echo -e "\n\e[1mAPI key is \e[0;32m$api\e[0m\n"

while true; do
	read -p $'\e[1mEnter your Domains name, without the nya.je:\e[0m ' domain 
  if [ -z "$domain" ]; then
	echo -e "\e[1;91mPlease Specify Domain Name!!!!\e[0m\n"
  else
	break
  fi
done
echo -e "\n\e[1mDomain Name is \e[0;32m$domain\e[0m\n"

PS3=$'\n\e[1mChoose an action: \e[0m'
options=("Update DDNS" "Show Queries" "Exit")

select opt in "${options[@]}"; do
  case $opt in
    "Update DDNS")  Update; exit 0;;
    "Show Queries")   Query; exit 0;;
    "Exit")           echo -e "\e[1mGoodbye.\e[0m"; exit 0;;
    *) echo -e "\e[1;31mInvalid option. Try again.\e[0m" ;;
  esac
done
}

# -q Option, Print HTTP Queries
Query() {
Varcheck

Nettest
	echo -e "\n\e[1mGetting IP Addresses...\n\e[0m"
Ipget
	echo -e "\n\e[1mHTTP Queries\n\e[0m"
	if [ "$ip" != "" ]; then
        echo -e "\e[0mIPv4 HTTP Query:\e[1;36mcurl -fsS \"https://ddns.kicya.net/api/ipv4/update?domain=$domain&token=$api&ip=$ip\"\e[0m"
        fi
        if [ "$ipv6" != "" ]; then
        echo -e	"\e[0mIPv6 HTTP	Query:\e[1;36mcurl -6 -fsS \"https://ddns.kicya.net/api/ipv6/update?domain=$domain&token=$api&ip=$ipv6\"\e[0m"
        fi

}

# -u Option, Update DDNS
Update() {
Varcheck

Nettest
        echo -e "\n\e[1mGetting IP Addresses...\n\e[0m"
Ipget
Nsget
if [ "$cip" != "$ip" ]; then
        if [ "$ip" != "" ]; then
        curl -4 -fsS "https://ddns.kicya.net/api/ipv4/update?domain=$domain&token=$api&ip=$ip"  >> $dir/nya-je-v4.log 
        fi
else
	echo -e "\n\e[1;91mIPv4 Update Uneeded!\e[0m\n"
fi

if [ "$cipv6" != "$ipv6" ]; then
        if [ "$ipv6" != "" ]; then
	curl -6 -fsS "https://ddns.kicya.net/api/ipv6/update?domain=$domain&token=$api&ip=$ipv6" >> $dir/nya-je-v6.log
        fi
else
	echo -e "\n\e[1;91mIPv6 Update Uneeded!\e[0m\n"
fi

	if [ -f $dir/nya-je-v6.log ]; then
	v6log=$(cat $dir/nya-je-v6.log)
	if [[ $v6log =~ \"ok\":true ]] then
	echo -e "\n\e[1mIPv6 Updated\e[0m"
	else
	echo -e "\n\e[1;91mIPv6 Failed!\e[0m"
	fi
	fi

	if [ -f $dir/nya-je-v4.log ]; then
	v4log=$(cat $dir/nya-je-v4.log)
	if [[ $v4log =~ \"ok\":true ]] then
	echo -e "\n\e[1mIPv4 Updated\e[0m"
	else
	echo -e "\n\e[1;91mIPv4 Failed!\e[0m"
	fi
	fi
if  [ -f $dir/nya-je-v4.log ] && [ -f $dir/nya-je-v6.log ]; then
	echo "ipv4 $(cat $dir/nya-je-v4.log)\n ipv6\n $(cat $dir/nya-je-v6.log)" > $dir/nya-je.log
	rm $dir/nay-je-v4.log $dir/nay-je-v6.log
	else
	if [ -f $dir/nya-je-v4.log ]; then
	mv $dir/nya-je-v4.log $dir/nya-je.log
	fi
        if [ -f $dir/nya-je-v6.log ]; then
	mv $dir/nya-je-v6.log nya-je.log
	fi
	fi
}

while getopts "a:d:uqifph" option; do
   case $option in
      i) # interactive mode
         Interactive
	 exit 0;;
      a) # specify api key
         api="${OPTARG}" ;;
      d) # specify domain name
         domain="${OPTARG}" ;;
      u) # update ddns record
         Update
         exit 0;;
      q) # print http queries
         Query
         exit 0;;
      p) # print ip addr
         IP
         exit 0;;
      h) # display Help
         Help
         exit 0;;
   esac
done

