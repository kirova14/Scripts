#!/bin/bash
##############################################################################
#
#      Author:  Sicinthemind
#        Date:  03-04-2014
#     Purpose:  Get off my lawn!
#
##############################################################################
#Grab Updated IANA Address Space Assignments only if Newer Version
wget -N https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.txt 2&>1 > /dev/null
assigned=ipv4-address-space.txt
if [[ -e $assigned ]]; then
	echo "File downloaded successfully"'!'
fi
arrayregistry=( afrinic apnic arin lacnic ripe )
for registry in "${arrayregistry[@]}"
do
	#$upreg="`echo "$registry" | tr '[:lower:]' '[:upper:]'`"
	echo "#!/bin/bash" > $registry.sh
	#echo "iptables -N $upreg"
    #Clean up the ipv4-address-space.txt file and keep useable IPs
    grep "$registry" $assigned | sed 's/\/8/\.0\.0\.0\/8/g'| colrm 15 > $registry-tmp1.txt
    ip=($(cat $registry-tmp1.txt))
    for ip in "${ip[@]}"
    do
        echo $ip | sed -e 's/"   "//g'  > $registry-tmp2.txt
        #INSERT OR MODIFY YOUR COMPATIBLE FIREWALL RULES HERE
        #This section creates the country to block.        
        echo "iptables -A INPUT -s $ip -j DROP" >> $registry.sh
        chmod +x $registry.sh
    done
    rm $registry-tmp1.txt -f
    rm $registry-tmp2.txt -f
done


-A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-INPUT-Dropped: " --log-level 4
-A OUTPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-OUTPUT-Dropped: " --log-level 4