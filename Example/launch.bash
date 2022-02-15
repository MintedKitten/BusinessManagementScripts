#!/bin/bash
# Management Files
# Start with a Splash Screen
# Get restaurant name rom Business.conf
CONF=$(cat Business.conf)
INDEX=`expr index "$CONF" =`
NAME="${CONF:$INDEX}"
# GUI using yad and zenity (zenity also would've worked but less flexible)
# Display to text-info fontsize is 32 name in the middle
FONT_SIZE=32
TEXT='<span font="'"$FONT_SIZE"'">Welcome to</span>\n<span font="'"$FONT_SIZE"'"><b>'"$NAME"'</b></span>\n<span font="'"$FONT_SIZE"'">Management Software</span>'
yad --info --title="Management Software" --text="$TEXT" --no-wrap --justify="center" --no-buttons --geometry=300x200 --timeout=2
# Login
# First Input Username and Password
USRPSW=$(yad --geometry=300x150 --text="Please Login" --justify="center" --title "Management Software" --form --field="Username" --field="Password:H")
OPTION=$?
if [ "$OPTION" -ne 0 ]
then
	TEXT='<span foreground="red" font="'"$FONT_SIZE"'">Login was Canceled</span>'
	yad --info --image=dialog-warning --geometry=300x50 --title="Abort Management Software" --text="$TEXT" --no-buttons --timeout=3 --justify="center"
	exit 0
fi
echo "$USRPSW"  #debug username password
USERNAME=$(echo "$USRPSW" | awk 'BEGIN {FS="|"} {print $1}')
PASSWORD=$(echo "$USRPSW" | awk 'BEGIN {FS="|"} {print $2}')
# Read user account file, read csv file
FILE=users.csv
OLDIFS=$IFS
IFS=","
HEADER=1
MATCH=0
USERINFO=""
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read username password firstname lastname
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	if [[ "$USERNAME" == "$username" && "$PASSWORD" == "$password" ]]
	then
		MATCH=1
		USERINFO="$firstname $lastname"
	fi
done < $FILE
IFS=$OLDIFS
# If there's a user in database, login, otherwise, error and exit
if [ "$MATCH" -ne 1 ]
then
	TEXT='<span foreground="red" font="'"$FONT_SIZE"'">Username or Password is incorrect</span>'
	yad --info --image=dialog-warning --title="Management Software" --text="$TEXT" --no-buttons --timeout=3 --justify="center" 
	exit 2
fi
TEXT='<span font="'"$FONT_SIZE"'">Welcome </span><span foreground="red" font="'"$FONT_SIZE"'">'"$USERINFO"'!</span>\nto <b>'"$NAME"'</b> Management Software'
yad --info --title="Login Successfully" --text="$TEXT" --no-buttons --timeout=3 --justify="center"
# After Login
# Check Date and Raw Material of Current Date, if exists display value and edit button, otherwise display new and new file
# Check if file exists, no create new, yes skip
NOW=$(date +%d-%m-%y)
STOCKFILE=Daily_Stock/stock_$NOW.csv
if [ ! -f "$STOCKFILE" ]
then
	touch $STOCKFILE
	echo "Material,Price,Amount,Type" >> $STOCKFILE
# Read needed materials, read csv file, and create a dummy file
	FILE=raw_material_cost.csv
	OLDIFS=$IFS
	IFS=","
	HEADER=1
	[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
	while read material cost type
	do
		[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
		amount='0'
		[[ "$type" == "Daily" ]] && { amount="-";}
		echo "$material,$cost,$amount,$type" >> $STOCKFILE
	done < $FILE
	IFS=$OLDIFS
	TEXT='<span>Can'"'"'t find today'"'"'s Stock File.</span>\n<span>Created a new file at </span><b>'"$STOCKFILE"'</b><span></span>'
	yad --info --title="Management Software" --text="$TEXT" --timeout=2 --no-buttons	
fi
# Read the stock file, display the current amount, and Close or Edit
TEXT="Current Raw Materials Amount - $NOW"$'\n'"Total cost ="
YADLIST="--title="'"'"Today""'""s Stock"'"'" --button=Close!gtk-cancel:1 --button=Edit!gtk-edit:0 --list --no-selection --column=Material --column=Cost --column=Amount -- "
FILE=$STOCKFILE
OLDIFS=$IFS
IFS=","
HEADER=1
TOTAL=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read material cost amount type
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	[[ "$type" == "Daily" ]] && { amount="-Daily"; }
	YADLIST+=" $material $cost $amount"
	[[ "$type" == "Daily" ]] && { amount=1; }
	TOTAL=`expr $TOTAL + $(($cost * $amount))`
done < $FILE
IFS=$OLDIFS
YADLIST="yad --text="'"'"$TEXT $TOTAL"'"'" $YADLIST"
eval "$YADLIST"
OPTION="$?"
if [ "$OPTION" -ne 0 ]
then
	TEXT='<span font="'"$FONT_SIZE"'">Exiting Management Software</span>\nThank you.'
	yad --info --title="Management Stock terminated" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
# Edit the file, create form to input data
TEXT="Edit Stock - $NOW"$'\nMaterial - Cost'
YADFORM="yad --form --title="'"'"Today""'""s Stock"'"'" --text="'"'"$TEXT"'"'" --align="'"'"center"'"'" --column=1"
FILE=$STOCKFILE
OLDIFS=$IFS
IFS=","
HEADER=1
NUM=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read material cost amount type
do
	[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
	[[ "$type" == "Daily" ]] && { continue; }
	YADFORM+=" --field="'"'"$material - $cost: :NUM"'"'" "'"'"$amount!0..1000"'"'
	NUM=`expr $NUM + 1`
done < $FILE
IFS=$OLDIFS
RESTOCK=$(eval "$YADFORM")
OPTION="$?"
if [ "$OPTION" -ne 0 ]
then
	TEXT='<span foreground="black" font="'"$FONT_SIZE"'">Discarding Change</span>\nExiting..'
	yad --info --title="Management Software" --text="$TEXT" --no-buttons --timeout=2 --justify="center"
	exit 0
fi
FILE=$STOCKFILE
OLDIFS=$IFS
IFS=","
N=0
[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
while read material cost amount type
do
	if [[ "$type" == "Daily" ]]
	then
		amount="-";
	else
		if [[ "$N" -gt 0 && "$N" -le "$NUM" ]] 
		then
			amount=$(echo "$RESTOCK" | awk 'BEGIN {FS="|"} {print $'"$N"'}')
		fi
	N=`expr $N + 1`
	fi
	echo "$material,$cost,$amount,$type" >> "$STOCKFILE.tmp"
done < $FILE
IFS=$OLDIFS
cp -f "$STOCKFILE.tmp" "$STOCKFILE"
rm "$STOCKFILE.tmp"
TEXT='<span>File save at </span><b>'"$STOCKFILE"'</b><span></span>\nProgram Terminating..'
yad --info --title="Stock Saved" --text="$TEXT" --no-buttons --timeout=3
exit 0
