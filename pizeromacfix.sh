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
echo "checking network interfaces..."
interfaces=($(ifconfig | grep -Eio '^[[:alnum:]]*'))
for i in ${interfaces[*]}; do
	echo "interface $i"
	macaddress="$(ifconfig $i | grep ether | grep -Eo '[[:alnum:]\:]{17}')"
	echo "mac address is $macaddress"
	if ["$macaddress" == "00:e0:4c:53:44:58" ]
	then
		echo "00:e0:4c:53:44:58 found on $i. beginning spoof"
		sudo ip link set $i down #disables interface
		timeout=30 #number of loop cycles (1s sleep) before aborting to prevent infinite loop
		while true; do #loop to ensure that the interface is down before attempting to spoof
			if $(ifconfig | grep $i > /dev/nul) #not using grep will result in a false positive
			then
				echo "Waiting for $i to be disabled..."
				sleep 1
				let timeout--
				continue
			elif [ "$timeout" == "0" ]
			then
				"Timeout reached. Moving on."
				break
			else
				"$i is down. Moving on."
				break
			fi
		done
		sudo ip link set $interface address "$macprefix""$pizeronum"
		sudo ip link set $i up
		macaddress="$(ifconfig $i | grep ether | awk -F ' ' '{print $2}')"
		if ["$macaddress" == "00:e0:4c:53:44:58" ] #checks again to verify that the mac address has been updated successfully
		then
			echo "MAC address update successful for $i."
		else
			echo "MAC address update was unsuccessful for $i."
		fi
	fi
done
