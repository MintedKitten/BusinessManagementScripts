#!/bin/bash 
# Operating Files
# Read menu, display in form with scroll number, then display the order
echo -e "\e[38;5;214mDebug\e[39m"
CONF=$(cat Business.conf)
INDEX=`expr index "$CONF" =`
NAME="${CONF:$INDEX}"
FONT_SIZE=32
TEXT='<span font="'"$FONT_SIZE"'">Welcome to</span>\n<span font="'"$FONT_SIZE"'"><b>'"$NAME"'</b></span>\n<span font="'"$FONT_SIZE"'">Ordering Software</span>'
yad --info --title="Ordering Software" --text="$TEXT" --no-wrap --justify="center" --no-buttons --geometry=300x200 --timeout=2
NOW=$(date +%d-%m-%y)
echo "$NOW"
SELLFILE=Daily_Sell/sell_$NOW.csv
if [ ! -f "$SELLFILE" ]
then
	touch "$SELLFILE"
	TEXT='<span>Can'"'"'t find today'"'"'s Stock File.</span>\n<span>Created a new file at </span><b>'"$SELLFILE"'</b><span></span>'
	yad --info --title="Ordering Software" --text="$TEXT" --timeout=2 --no-buttons
	echo "Id,Name,Price,Order" >> "$SELLFILE"
fi
echo "$(cat $SELLFILE)"
# Read the file compute the Total Price as Revenue
FILE=$SELLFILE
OLDIFS=$IFS
IFS=","
HEADER=1
TOTAL=0
LASTID=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read id name price order
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	TOTAL=`expr $TOTAL + $price`
	LASTID=$id
done < $FILE
IFS=$OLDIFS
TEXT='<span font="'"$FONT_SIZE"'">Today'"'"'s date is '"$NOW"'</span>\n<span font="'"$FONT_SIZE"'">Today'"'"'s revenue is '"$TOTAL"'</span>'
yad --title="Ordering Software" --text="$TEXT"  --button=Exit!gtk-cancel:1 --button="New Order"!gtk-edit:0
OPTION="$?"
if [ "$OPTION" -ne 0 ]
then
	TEXT='<span font="'"$FONT_SIZE"'">Exit Ordering Software</span>\nExiting..'
	yad --info --title="Management Software" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
# Edit the file, create form to input data
TEXT="The Menu, Please enter the order - Date - $NOW"$'\nMenu - Price'
YADFORM="yad --form --title="'"'"The Menu"'"'" --text="'"'"$TEXT"'"'" --align="'"'"center"'"'" --button=Cancel!gtk-cancel:1 --button=Confirm!gtk-apply:0 --column=1 --field="'"'"Customer name"'"'":TEXT '' "
FILE=menu.csv
OLDIFS=$IFS
IFS=","
HEADER=1
NUM=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read id name price order
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	YADFORM+=" --field="'"'"$name - $price: :NUM"'"'" "'"'"0!0..1000"'"'
	NUM=`expr $NUM + 1`
done < $FILE
IFS=$OLDIFS
echo "$NUM"
NAMEORDER=$(eval "$YADFORM")
OPTION="$?"
echo "$NAMEORDER $OPTION"
if [ "$OPTION" -ne 0 ]
then
	TEXT='<span font="'"$FONT_SIZE"'">Exit Ordering Software</span>\nExiting..'
	yad --info --title="Ordering Software" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
CUSNAME=$(echo "$NAMEORDER" | awk 'BEGIN {FS="|"} {print $1}')
if [[ "$CUSNAME" == "" ]]
then
	TEXT='<span foreground="red" font="'"$FONT_SIZE"'">No name was given</span>\n(No customer) Exiting..'
	yad --info --image=dialog-warning --title="Ordering Software" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
ISORDER=0
ORDER=""
for (( i=2; i<="$NUM"+1; i++ ))
do
	tmp="$""$i"
	tmpor=$(echo "$NAMEORDER" | awk 'BEGIN {FS="|"} {print '"$tmp"'}')
	[[ "$tmpor" -ne 0 ]] && { ISORDER=1; }
	ORDER+="$tmpor"
	[[ "$i" -ne "$NUM"+1 ]] && { ORDER+="|"; }
done
if [ "$ISORDER" -eq 0 ]
then
	TEXT='<span foreground="red" font="'"$FONT_SIZE"'">No order was made</span>\n(All order was 0) Exiting..'
	yad --info --image=dialog-warning --title="Ordering Software" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
echo "$CUSNAME $ORDER"
FILE=menu.csv
OLDIFS=$IFS
IFS=","
HEADER=1
PRICE=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read id name price order
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	SUBPRICE=`expr $(echo "$ORDER" | awk 'BEGIN {FS="|"} {print $'"$id"'}')`
	PRICE=`expr "$PRICE" + $(("$SUBPRICE" * "$price"))`
done < $FILE
IFS=$OLDIFS
echo "$PRICE"
NEXTID=`expr $LASTID + 1`
echo "$NEXTID,$CUSNAME,$PRICE,$ORDER" >> "$SELLFILE"
TEXT='<span  font="'"$FONT_SIZE"'">Thank you for purchasing!</span>\n'"Order ID = $NEXTID"'\n'"Customer name = $CUSNAME"'\n'"Price = $PRICE"
	yad --info --title="Ordering Software" --text="$TEXT" --button=Exit!gtk-apply:0 --justify="center" --timeout=10
