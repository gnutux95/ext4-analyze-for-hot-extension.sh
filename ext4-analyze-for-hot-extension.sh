#!/bin/bash  
# Copyright (C) 2015 GnuTux 95 <tux95mail@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Goal : hot check possible extension of a FS ext4
# version 1.00

MODE_VERBEUX=0
PROGNAME=$(basename $0 | cut -d . -f1)
DUMPE2FS=/sbin/dumpe2fs
LOG=${PROGNAME}.log

#LVNAME
ARG1=$1
#Taille 
SIZE=$2
ARG2=$2

#init flag
FLAG=0

#Functions
affich(){
MESS=$1
VERB=$2

if [ $VERB -eq 1 ]
 then
	echo "$MESS"
 fi

}
analyze_resize_inode(){
  LVNAME=$1

  if [ `$DUMPE2FS $LVNAME 2>/dev/null | grep -i features | grep -c resize_inode 2>&1` -eq 1 ]
    then
	affich "Resize_inode Option AVAILABLE " $MODE_VERBEUX
	FLAG=0
	return 1
    else
	affich "Resize_inode Option UNAVAILABLE" $MODE_VERBEUX
 	affich "This file system is not resizable cold nor hot" $MODE_VERBEUX	
	FLAG=1
	return 0
  fi
}


convert_M(){

VAL=$1

UNIT=$(echo "$VAL" | sed -n 's/^[0-9].*\([GgMmkKTt]\)/\1/p' )
SIZE=$(echo "$VAL" | sed -n 's/[[:alpha:]]//p')
#Remplace les "," pour en "."
SIZE=$(echo "$SIZE" | sed 's%,%.%g')

#converting 
case $UNIT in
M|m)
SIZE=${SIZE}
;;
k|K)
SIZE=$(echo "$SIZE / 1024" | bc )
;;
G|g )
SIZE=$(echo "$SIZE * 1024" | bc )
;;
T|t)
SIZE=$(echo "$SIZE * 1024 * 1024" | bc )
;;
*) echo "End script: $ UNIT type of unit is not supported - only for T Tio Gio G, M or K for Mio Kio"
exit 2
;;
esac


#Convertit en entier
SIZE=$(printf "%.0f\n" $SIZE)

export SIZE
}

info_GDT(){
if [ $MODE_VERBEUX -eq 1 ]
	then	
		$DUMPE2FS $LVNAME 2>/dev/null | grep -i GDT
	fi
}

analyze_gdt(){
 LVNAME=$1


  if [ `$DUMPE2FS $LVNAME 2>/dev/null | grep -w -c "Reserved GDT blocks:" 2>&1` -eq 1 ]
    then
        affich "GDT blocks Reserved [ PRESENT ] " $MODE_VERBEUX
	FLAG=0
	info_GDT
        return 1
    else
        affich "GDT blocks Reserved [NO PRESENT] " $MODE_VERBEUX
	FLAG=1
        return 0
  fi
}

#advise for extension
avis_agrandissement(){
local SIZE=$1
local MAX=$2

if [ $SIZE -le $MAX ]
  then
		
	FLAG=0		
                affich "The extension of REQUESTED $ARG2 compatible with the initial journal size" $MODE_VERBEUX
	return 1
else
	FLAG=1
               affich "The extension of REQUESTED $ARG2 isn't compatible with the initial journal size" $MODE_VERBEUX
	return 0
fi

}

#overall opinion
avis_sur_l_ensemble(){

if [ $FLAG -eq 1 ]
then
  affich " " $MODE_VERBEUX
  echo "Extension ext4 has MANDATORY COLD: umount the necessary FS "
  affich " " $MODE_VERBEUX
 exit 1
else
 affich " " $MODE_VERBEUX
 echo "Possible hot extension in ext4"
 affich " " $MODE_VERBEUX
 exit 0
fi

}

#recommended journal
recommand_journal(){
local SIZE=$1

if [ $SIZE -lt 65 ]
then
       JS="NO RECOMMENDATION"

elif [ $SIZE -lt 256 ]
then
	JS=4Mo
elif [ $SIZE -lt 512 ]
then 
	JS=8Mo
elif [ $SIZE -lt 1024 ]
then
        JS=16Mo
elif [ $SIZE -lt 2048 ]
then
        JS=32Mo
elif [ $SIZE -lt 4096  ]
then
        JS=64Mo
else
        JS=128Mo
fi

affich "Recommanded size of journal : $JS"  $MODE_VERBEUX

}


analyze_journal(){
 LVNAME=$1

convert_M $SIZE

JS=$($DUMPE2FS $LVNAME 2>/dev/null | grep -w "Journal\ size" | awk '{print $NF}'
)


case $JS in 
4096k)
	affich "Journal Size $JS." $MODE_VERBEUX
	affich "Extension Max 62Go"	$MODE_VERBEUX
	
	avis_agrandissement $SIZE 63488

;;

8M) 
	affich "Journal Size $JS." $MODE_VERBEUX
	affich "Extension Max 63Go" $MODE_VERBEUX
	 avis_agrandissement $SIZE 64512

;;

16M)
	affich "Journal Size $JS."  $MODE_VERBEUX
	affich "Extension Max 504Go"  $MODE_VERBEUX
	avis_agrandissement $SIZE 516016
;;
32M)
	affich "Journal Size $JS."  $MODE_VERBEUX
	affich "Tested OK up to 600G (untested beyond)"  $MODE_VERBEUX
	avis_agrandissement $SIZE 614400

;;
64M)
affich "Journal Size $JS."  $MODE_VERBEUX
affich "Tested OK up to 1T (untested beyond)"  $MODE_VERBEUX
avis_agrandissement $SIZE 614400
;;
128M)
affich "Journal Size $JS. "  $MODE_VERBEUX
affich "Extension of the warranty up to 3.1T (untested beyond)"  $MODE_VERBEUX
avis_agrandissement $SIZE 3250585
;;

*) echo "Value not found - no possible advice " 
;;
esac	

recommand_journal $SIZE

}

root(){
if [ `id -u` -ne 0 ]
 then
	echo "You must be root to launch this script"
	exit 3
fi
}

usage(){
	echo "Usage : $0 full_lv_path target_size_desired[KkMmGgTt]"
	echo "Ex  : $0 /dev/vg_mydata/lv_mylv 750G"
	exit 4
}

testlv(){
 	local LVNAME=$1
   		
	if [ ! -b $LVNAME ]
	 then
	        echo "LV $LVNAME not found..." 
		exit 6
	fi
}

# test of size
testsize(){
 	local SIZE=$1

	UNIT=$(echo "$SIZE" | sed -n 's/^[0-9].*\([GgMmkKTt]\)/\1/p' )

	VAL=$(echo "$SIZE" | sed -n 's/[[:alpha:]]//p')

	VAL=$(echo "$VAL" | sed 's%\.%%g' | sed 's%\,%%g' ) 
	
	case $UNIT in 
	G|g|M|m|K|k|T|t) 
		
	#affich "This unity $UNIT is not supported..." $MODE_VERBEUX
	;;

	*) 
		echo "This unity $UNIT is not supported..." 
		exit 8
	
	esac
		
	if  [ "$(echo $VAL | grep  -v "^[[:digit:]]*$")" ]||[ `echo "$SIZE" | egrep -o ',|\.' | wc -l` -gt 1 ]
	then
		 echo "this value is not supported..." 
		exit 9
	fi

}

#main()

if [ ! -z $ARG1 ]&&[ ! -z $ARG2 ]
then
#
#while getopts ":v" opt; do
#  case $opt in
#    v)
#      echo "Mode verbeux" >&2
#      MODE_VERBEUX=1
#      ;;
#    *)
##      echo "Invalid option: -$OPTARG" >&2
#       ARG1=
#       ARG2=
#      ;;
#  esac
#done
	#TEST VAR
	testsize $ARG2
	testlv $ARG1
	
	#ANALYSE	
	analyze_resize_inode $ARG1
	analyze_gdt $ARG1
	analyze_journal $ARG1
	avis_sur_l_ensemble
else
	usage
fi
