#!/bin/bash
#---------------------------------------------------------------------------------------
#title: Pi Zero MAC Fix
version="0.1.0"
#author: Matt Hooker
#created: 2020-06-12
#maintainer: Matt Hooker
modifiedDate="2020-06-12"
#this script helps resolve conflicts stemming from the fact that so many chinese ethernet to USB adapters use a cloned realtek chip with the mac address of 00:e0:4c:53:44:58
#---------------------------------------------------------------------------------------
macprefix="00:e0:4c:FF:FF:" #standardized prefix for the new mac address. can be customized
pizeronum=$(hostname | grep -Eo '[0-9]{2}$') #retrieves the two numeric digits at the end of the hostname. assumes hostname ends as such
checking network interfaces...
for interface in $(ifconfig | grep -Eio '^[[:alnum:]]*')
do
	if ["$(ifconfig $interface | grep ether)" == "00:e0:4c:53:44:58" ]
	then
		echo "00:e0:4c:53:44:58 found on $interface. beginning spoof"
		sudo ip link set $interface down #disables interface
		timeout=30 #number of loop cycles (1s sleep) before aborting to prevent infinite loop
		while true #loop to ensure that the interface is down before attempting to spoof
		do
			if $(ifconfig | grep $interface > /dev/nul) #not using grep will result in a false positive
			then
				echo "Waiting for $interface to be disabled..."
				sleep 1
				let timeout--
				continue
			elif [ "$timeout" == "0" ]
			then
				"Timeout reached. Moving on."
				break
			else
				"$interface is down. Moving on."
				break
			fi
		done
		sudo ip link set $interface address "$macprefix""$pizeronum"
		sudo ip link set $interface up
		if ["$(ifconfig $interface | grep ether)" == "00:e0:4c:53:44:58" ] #checks again to verify that the mac address has been updated successfully
		then
			echo "MAC address update successful for $interface."
		else
			echo "MAC address update was unsuccessful for $interface."
		fi
	fi
done
