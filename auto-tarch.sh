#!/bin/bash

# Help Text
Help() {
   echo -e "\e[1mAutomated TAR archiver\e[0m"
   echo
   echo -e "Syntax: auto-tarch -a ARCHIVEDIR -d DESTINATIONDIR -n NAME -c COMPRESSION [-h|-i]"
   echo -e "Options:"
   echo -e "\e[1m-h\e[0m   Print this Help."
   echo -e "\e[1m-i\e[0m   Interactive Mode."
   echo -e "\e[1m-a\e[0m   Directory to Archive."
   echo -e "\e[1m-d\e[0m   Destination Directory."
   echo -e "\e[1m-n\e[0m   Archive Name."
   echo -e "\e[1m-c\e[0m   Archive Compression."
   echo
}

# Check if we're root, exit if not
Sudocheck() {
if [ "$(id -u)" != 0 ]; then
  echo -e "\e[1mThis script needs to be run as root, or with \e[0;32msudo\e[0m\e[1m.\e[0m"
  exit 1
fi
}

# Archiving function
Archive() {
while true; do
  read -r -p "Enter a name for the archive (required): " name
  if [ -z "$name" ]; then
    echo -e "\e[1mName cannot be empty. \e[1;31mTry again.\e[0m"
  else
    break
  fi
done

echo -e "\e[1mName set to: \e[0;32m$name\e[0m"

echo -e "\e[1mMounting \e[0;32m$archdir\e[0m"; mount -o ro $archdir

  if [ -z "$comp" ]; then
	echo -e "\e[1mRunning \e[0;32mtar cavf $destdir/$name.tar -C$archdir . --transform \"s,^,$name/,\"\e[0m"
	tar cavf $destdir/$name.tar -C$archdir . --transform "s,^,$name/,"
  else
	echo -e "\e[1mRunning \e[0;32mtar cavf $destdir/$name.tar.$comp -C$archdir . --transform \"s,^,$name/,\"\e[0m"
	tar cavf $destdir/$name.tar.$comp -C$archdir . --transform "s,^,$name/,"
  fi

echo -e "\e[1mUnmounting \e[0;32m$archdir\e[0m"; umount $archdir
}

# Automatic archiving
AutoArchive() {

Sudocheck

  if [ -z "$name" ]; then
    echo -e "\e[1mName cannot be empty. \e[1;31mTry again.\e[0m"
    exit 1
  fi

  if [ -z "$archive" ]; then
    echo -e "\e[1mArchive cannot be empty. \e[1;31mTry again.\e[0m"
    exit 1
  fi

  if [ -z "$destdir" ]; then
    echo -e "\e[1mDestination cannot be empty. \e[1;31mTry again.\e[0m"
    exit 1
  fi

echo -e "\e[1mMounting \e[0;32m$archdir\e[0m"
mount -o ro $archdir

  if [ -z "$comp" ]; then
	echo -e "\e[1mRunning \e[0;32mtar cavf $destdir/$name.tar -C$archdir . --transform \"s,^,$name/,\"\e[0m"
	tar cavf $destdir/$name.tar -C$archdir . --transform "s,^,$name/,"
  else
	echo -e "\e[1mRunning \e[0;32mtar cavf $destdir/$name.tar.$comp -C$archdir . --transform \"s,^,$name/,\"\e[0m"
	tar cavf $destdir/$name.tar.$comp -C$archdir . --transform "s,^,$name/,"
  fi

echo -e "\e[1mUnmounting \e[0;32m$archdir\e0m"
umount $archdir
}

Questions() {
# Populate Variables
while true; do
  read -r -p "Enter a Compression suffix (optional): " comp
  if [ -z "$comp" ]; then
    echo -e "\e[1mCompression suffix unset\e[0m"; unset comp && break
  else
    echo -e "\e[1mCompression set to: \e[0;32m$comp\e[0m"; break
  fi
done

while true; do
  read -r -p "Enter a directory to archive (required): " archdir
  if [ -z "$archdir" ]; then
    echo -e "\e[1mArchive directory cannot be empty. \e[1;31mTry again."
  else
    break
  fi
done
echo -e "\e[1mArchive directory set to: \e[0;32m$archdir\e[0m"

while true; do
  read -r -p "Enter a destination directory (required): " destdir
  if [ -z "$destdir" ]; then
    echo -e "\e[1mDestination directory cannot be empty. \e[1;31mTry again."
  else
    break
  fi
done
echo -e "\e[1mArchive directory set to: \e[0;32m$destdir\e[0m"
}

# Menu system
Menu() {
PS3=$'\n\e[1mChoose an action: \e[0m'
options=("Reanswer" "Archive" "Exit")

select opt in "${options[@]}"; do
  case $opt in
    "Reanswer")  Questions;;
    "Archive")   Archive;;
    "Exit")           echo -e "\e[1mGoodbye.\e[0m"; exit 0;;
    *) echo -e "\e[1mInvalid option. \e[1;31mTry again.\e[0m" ;;
  esac
done
}

Interactive() {
Sudocheck; Questions; Menu && exit 0 || exit 1
}

if [ $# -eq 0 ];
then
    Interactive
    exit 0
fi

while getopts "Afa:d:n:c:ih" option; do
   case $option in
      i) # interactive mode
         Interactive
         exit 0;;
      a) # specify archive dir
       	 archdir="${OPTARG}" ;;
      d) # specify destination dir
       	 destdir="${OPTARG}" ;;
      n) # Archive name
	 name="${OPTARG}" ;;
      c) # Compression suffix
         comp="${OPTARG}" ;;
      A) # Automatic archive
	 AutoArchive
       	 exit 0;;
      f) # Quick archive, needs -d, -a, optionally -c
	 Archive
       	 exit 0;;
      h) # display Help
	 Help
       	 exit 0;;
   esac
done
