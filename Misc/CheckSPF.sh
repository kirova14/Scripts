#!/bin/bash
######################################################################################
#
#       Author   :  Sicinthemind
#       Date     :  8/4/2020
#       Purpose  :  Collect the DNS records for SPF and DMARC for a given domain.
#
######################################################################################

function usage() {
        echo "$0 -switch parameter"
        echo "     -d domain"
        echo "     -f domain list"
        echo "     -e email list"
        exit 1
}

while getopts e:d:f: o
do      case "$o" in
        d)
                domains=("$OPTARG")
                ;;
        e)
                contacts="$OPTARG"
                domains=($(cat $contacts | cut -d '@' -f2))
                ;;
        f)
                contacts="$OPTARG"
                domains=($(cat $contacts))
                ;;
        [?])
                usage;;
        esac
done
if [ $OPTIND -eq 1 ]; then
        usage
fi

tred="\e[91;1m"
tgrn="\e[92;1m"
tylw="\e[93;1m"
trst="\e[0m"
dmarcpolnone='p=none'
dmarcpolquar='p=quarantine'
dmarcpolrejc='p=reject'
echo 'DNS Name  SPF Status      DMARC Status    SPF Record      DMARC Record' > spfcheckresults.csv

for d in "${domains[@]}"; do
        spfpolicy=''
        spfstatus=''
        spflookup=''
        dmcpolicy=''
        dmcstatus=''
        dmclookup=''
        if [ ! -z "$dnslookup" ]; then
                unset dnslookup;
        fi
        echo -en "$d\t"

        spflookup=$(dig $d TXT | grep -o '"v=spf1.*"' | head -n 1 | sed -e 's/\t/ /g' | sed -e 's/"//g' | sed -e 's/\n//g')
        dmclookup=$(dig _dmarc.$d TXT | grep -Eo '"v=DMARC1.*"' | head -n 1 | sed -e 's/\t/ /g')

        if [ -z "$spflookup" ]; then
                #echo -en "SPF:"$tred" ALLOWALL $trst"
                spfstatus=$tred"ALLOWALL"$trst
        else
                spfpolicy=$(echo "$spflookup" | grep -o '[~+-]all')
                case $spfpolicy in
                        ~all)
                                echo -en "SPF:"$tylw" SoftFail  $trst"
                                spfstatus=$tylw"SoftFail"$trst
                                ;;
                        -all)
                                echo -en "SPF:"$tgrn" Strict    $trst"
                                spfstatus=$tgrn"Strict"$trst
                                ;;
                        +all)
                                echo -en "SPF:"$tred" Pass        $trst"
                                spfstatus=$tred"Permissive"$trst
                                ;;
                        *)
                                echo -en "SPF:"$tylw" Possibly Misconfigured     $trst"
                                spfstatus=$tylw"Misconfigured"$trst
                                ;;
                esac
        fi
        if [ -z "$dmclookup" ]; then
                echo -en "DMARC:"$tred" NONE    $trst\n"
                dmcstatus="NONE"
        else
                dmcpolicy=$(echo "$dmclookup" | grep -o 'p=\w*;' | head -n 1 | sed -e 's/;//g')
                dmcaudit=$(echo "$dmclookup" | grep -o 'rua=[A-Za-z0-9\_\:\.\@\-\;]*' | head -n 1 | sed -e 's/;//g')
                dmcforen=$(echo "$dmclookup" | grep -o 'ruf=[A-Za-z0-9\_\:\.\@\-\;]*' | head -n 1 | sed -e 's/;//g')
                case $dmcpolicy in
                        $dmarcpolnone)
                                echo -en "DMARC:"$tred" Not Enforced    $trst"
                                dmcstatus=$tred"Not Enforced"$trst
                                ;;
                        $dmarcpolquar)
                                echo -en "DMARC:"$tgrn" Good    $trst"
                                dmcstatus=$tgrn"Good"$trst
                                ;;
                        $dmarcpolrejc)
                                echo -en "DMARC:"$tgrn" Good    $trst"
                                dmcstatus=$tgrn"Good"$trst
                                ;;
                        *)
                                echo -en "DMARC:"$tred" MISCONFIGURED   $trst"
                                dmcstatus=$tred"Misconfigured"$trst
                                ;;
                esac

                if [ -z "$dmcaudit" ]; then
                        echo -en "DMARC Audit:"$tred" NONE      $trst"
                        dmca=$tred"NONE"$trst
                else
                        echo -en "DMARC Audit:"$tgrn" IN-USE    $trst"
                        dmca=$tgrn"IN-USE"$trst
                fi
                if [ -z "$dmcforen" ]; then
                        echo -en "DMARC Foren.:"$tred" NONE     $trst\n"
                        dmcf=$tred"NONE"$trst
                else
                        echo -en "DMARC Foren.:"$tgrn" IN-USE   $trst\n"
                        dmcf=$trst"IN-USE"$trst
                fi
        fi
        echo "$d        SPF: $spfstatus($spfpolicy)     DMARC: $dmcstatus($dmcpolicy - $dmcaudit)       $spflookup      $dmclookup" >> spfcheckresults.txt
done
