#!/bin/bash

# Usage dragonboard-ftdi FTDI_SERIAL command
# commands: reset, reset-fastboot

UART_RELAY=/usr/local/bin/uart_power.sh

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <ftdi_serial> <reset|reset-fastboot|on|off>"
	exit -1
fi

# Find ftdi sysfs path
USB_DEVICES=$(find -L /sys/bus/usb/devices/ -maxdepth 3 -name "serial" 2> /dev/null)
for i in ${USB_DEVICES}; do
	SERIAL=$(cat $i)
	if [ ${SERIAL} = $1 ]; then
		FTDI=$(dirname "$i")
		break
	fi
done

if [ -z ${FTDI} ]; then
	echo "FTDI with serial '$1' not found!"
	exit 1
fi

echo "Found FTDI at ${FTDI}"

if [ "$2" = "connect" ]; then
	TTY=`find ${FTDI}/* -name ttyUSB* | tail -n1`
	TTY=`basename ${TTY}`
	rm /var/lock/LCK..${TTY}
	microcom -p /dev/${TTY} -s 115200
	exit 0
fi

# Find base GPIO
GPIO_BASE=$(cat ${FTDI}/gpio/gpiochip*/base)

if [ -z ${GPIO_BASE} ]; then
	echo "No GPIO chip associated to the FTDI!"
	exit 1
fi

# Dragonboard specific
GPIO_RESET=${GPIO_BASE}
GPIO_VOLDOWN=$(expr ${GPIO_RESET} + 1)

echo "GPIO_RESET = ${GPIO_RESET}"
echo "GPIO_VOLDOWN = ${GPIO_VOLDOWN}"

if [ ! -e /sys/class/gpio/gpio${GPIO_RESET} ]; then
	echo "Exporting gpio${GPIO_RESET}"
	echo ${GPIO_RESET} > /sys/class/gpio/export
fi

if [ ! -e /sys/class/gpio/gpio${GPIO_VOLDOWN} ]; then
	echo "Exporting gpio${GPIO_VOLDOWN}"
	echo ${GPIO_VOLDOWN} > /sys/class/gpio/export
fi

echo "out" > /sys/class/gpio/gpio${GPIO_RESET}/direction
echo "out" > /sys/class/gpio/gpio${GPIO_VOLDOWN}/direction

GPIO_RESET=/sys/class/gpio/gpio${GPIO_RESET}/value
GPIO_VOLDOWN=/sys/class/gpio/gpio${GPIO_VOLDOWN}/value

if [ "$2" = "reset-fastboot" ]; then
	echo 0 > ${GPIO_VOLDOWN}
#	echo 0 > ${GPIO_RESET}
#	sleep 13
#	echo 1 > ${GPIO_RESET}
    ${UART_RELAY} reset /dev/ttyUartRelay 4
	sleep 3
	echo 1 > ${GPIO_VOLDOWN}
elif [ "$2" = "reset" ]; then
#	echo 0 > ${GPIO_RESET}
#	sleep 15
#	echo 1 > ${GPIO_RESET}
    ${UART_RELAY} reset /dev/ttyUartRelay 4
elif [ "$2" = "off" ]; then
#	echo "off-mode not supported"
     ${UART_RELAY} off /dev/ttyUartRelay 4
elif [ "$2" = "on" ]; then
#	echo 1 > ${GPIO_RESET}
#	echo 1 > ${GPIO_VOLDOWN}
    ${UART_RELAY} on /dev/ttyUartRelay 4
fi
