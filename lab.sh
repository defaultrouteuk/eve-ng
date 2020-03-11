#!/bin/bash
#
# Grep EVE logfile for console port of each router based on RID and last run
# call TERMINAL w/ tab label
# 
#
### BEGIN-of-SETUP
TERMINAL=ZOC              # Can be ZOC / SECURECRT / WINTERM
HOST=192.168.32.58        # Can be hard coded her or as command line argument for remote EVE-NG host
RUID=root                 # EVE-NG user (probably root)
### END-of-SETUP

### APPLICATION BASED ###
SECURECRT_PATH=/mnt/c/Program\ Files/VanDyke\ Software/Clients/SecureCRT.exe
ZOC_PATH=/Applications/zoc7.app
WINTERM_PATH=/usr/sbin/winterm
PUTTY_PATH=/usr/bin/putty

# Read command line input for EVE-NG host
if [ $# -eq 1 ]; then
   HOST=$1
fi

### BEST GUESS / WHAT AM I ###
LINUX_TERMINAL=
LINUX_ARGS=
LOGCP=/tmp/unl_wrapper.txt
PLATFORM=`uname -a | awk '{print $1}'`
OPLATFORM=`uname -a | awk '{print $4}'`
LOGFILE=/opt/unetlab/data/Logs/unl_wrapper.txt

# What wrappers am I going to check for in the logs
declare -a INSTANCE=("/opt/vpcsu/bin/vpcs" 
                     "/opt/unetlab/wrappers/iol_wrapper" 
                     "/opt/unetlab/wrappers/qemu_wrapper"
                     )

terminal () {
   # Function to define terminal arguements
   case $TERMINAL in
      SECURECRT)
         $SECURECRT_PATH /N $2 /T /TELNET $HOST $1 &
         ;;
      ZOC)
         open -n -a $ZOC_PATH --args /CONNECT=TELNET!$HOST:$1 /TABBED /TITLE:$2
         ;;
      WINTERM)
         $WINTERM_PATH -t $2 -iconic -c telnet $HOST $1
         ;;
      PUTTY)
         $PUTTY_PATH -telnet $HOST -P $1 -title $2 &
         ;;
   esac
}

### Setup password-less SSH login
# ssh-keygen -t rsa
# cat ~/.ssh/id_rsa.pub | ssh $RUID@$host 'cat >> .ssh/authorized_keys'

### Copy the eve-ng log file to this machine
# scp $RUID@$HOST:$LOGFILE /tmp/unl_wrapper.txt 1>/dev/null 2>&1
ssh $RUID@$HOST "tail -1000 $LOGFILE" > $LOGCP

if [ $0 = 1 ]; then
   echo "Can\'t copy the logfile from $HOST"
else
   if [ $PLATFORM = 'Linux' ]; then
      PLATFORM='Linux'
      if [ $OPLATFORM = '#1-Microsoft' ]; then
         PLATFORM='Windows'
      fi
   elif [ $PLATFORM = 'IRIX' ]; then
      PLATFORM='Irix'
   elif [ $PLATFORM = 'Darwin' ]; then
      PLATFORM='Mac'
   fi
fi


# for TYPE in ${INSTANCE[@]}
# do
#    echo $type
# done

### Iterate through array
for ((i=0; i<${#INSTANCE[@]}; i++))
do
   echo "index [$i] -> ${INSTANCE[$i]}"
   IFS=$'\n'

   case $i in
      0)
         # Virtual PC Loop
         # Setup the Array of elements from the logfile
         declare -a SocketArray=(`grep -n "${INSTANCE[$i]}" $LOGCP | awk -v OFS='\n' '{print $10,$14}'`)
         for ((c=0; c<${#SocketArray[@]}; c++))
         do
            # echo "${SocketArray[$c]} ${SocketArray[$(($c+1))]}" # Uncomment for DEBUG echo to screen of array 
            # nc -z $HOST ${SocketArray[$(($c+1))]} >/dev/null 2>&1; EC=$? 
	         cat 2>/dev/null < /dev/null > /dev/tcp/$HOST/${SocketArray[$(($c+1))]}; EC=$? # If this takes too long add 'timeout 1' before 'cat'
         if [ $EC == 0 ]; then
            terminal ${SocketArray[$(($c+1))]} ${SocketArray[$c]}
         fi
            # Increment array counter
            c=$(($c+1))
         done
         ;;
      1)
         # Cisco IOL Loop
         declare -a SocketArray=(`grep -n "${INSTANCE[$i]}" $LOGCP | awk -v OFS='\n' '{print $16,$8}' | sed 's/"//g;'`)
         for ((c=0; c<${#SocketArray[@]}; c++))
         do
            # echo "${SocketArray[$c]} ${SocketArray[$(($c+1))]}" # Uncomment for DEBUG echo to screen of array 
            # nc -z $HOST ${SocketArray[$(($c+1))]} >/dev/null 2>&1; EC=$? 
	         cat 2>/dev/null < /dev/null > /dev/tcp/$HOST/${SocketArray[$(($c+1))]}; EC=$? # If this takes too long add 'timeout 1' before 'cat'
         if [ $EC == 0 ]; then
            terminal ${SocketArray[$(($c+1))]} ${SocketArray[$c]}
         fi
            # Increment array counter
            c=$(($c+1))
         done
         ;;
      2)
         # QEMU Loop
         declare -a SocketArray=(`grep -n "${INSTANCE[$i]}" $LOGCP | awk -v OFS='\n' '{print $14,$8}'`)
         for ((c=0; c<${#SocketArray[@]}; c++))
         do
            # echo "${SocketArray[$c]} ${SocketArray[$(($c+1))]}"  # Uncomment for DEBUG echo to screen of array 
            # nc -z $HOST ${SocketArray[$(($c+1))]} >/dev/null 2>&1; EC=$?
	         cat 2>/dev/null < /dev/null > /dev/tcp/$HOST/${SocketArray[$(($c+1))]}; EC=$? # If this takes too long add 'timeout 1' before 'cat'
         if [ $EC == 0 ]; then
            terminal ${SocketArray[$(($c+1))]} ${SocketArray[$c]}
         fi
            # Increment array counter
            c=$(($c+1))
         done
         ;;
   esac

done
