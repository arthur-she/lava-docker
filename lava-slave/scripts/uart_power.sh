#!/bin/bash


#stty -F /dev/ttyUSB0 speed 9600 cs8 -cstopb -parenb && echo -e "\xFF\x01\x01\x02\xEE" > /dev/ttyUSB0
# Check the UART speed
#UART_SPEED=`stty -F $2 speed`

#if [ $UART_SPEED -ne "9600" ]; then
#    stty -F $2 speed 9600 cs8 -cstopb -parenb
#fi

useage (){
    echo $1 "[reset|on|off] UART_DEV RELAY_NO"
}

power_on (){
    CHKSUM=$(($2+1))
    echo -e "\xFF\x$2\x01\x$CHKSUM\xEE" > $1
    sleep 1
}

power_off (){
    CHKSUM=$(($2+0))
    echo -e "\xFF\x$2\x00\x$CHKSUM\xEE" > $1
    sleep 1
}

[ -n "`echo $2|grep dev`" ] || (useage $0 && exit -1)
stty -F $2 raw ispeed 9600 ospeed 9600 cs8 -ignpar -cstopb -echo

case $1 in
    "on")
        power_on $2 $3
        ;;
    "off")
        power_off $2 $3
        ;;
    "reset")
        power_off $2 $3
        power_on $2 $3
        ;;
    *)
        useage $0
        ;;
esac
#power_on $1 $2
