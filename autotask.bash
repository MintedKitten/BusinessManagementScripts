ACCOUNTFILE=$PATH/Daily_Accounting/accounting_$YESTERDAY.csv
STOCKFILE=$PATH/Daily_Stock/stock_$YESTERDAY.csv
SELLFILE=$PATH/Daily_Sell/sell_$YESTERDAY.csv
PATH=$OLDPATH
if [ -f "$ACCOUNTFILE" ]
then
	echo "Accounting already made for yesterday"
	exit 1
fi

# Report Stock
STOCKREPORT="Stock update on $YESTERDAY"
if [[ ! -f "$STOCKFILE" ]]
then
	STOCKREPORT="No Stock update on $YESTERDAY"
else
	FILE=$STOCKFILE
	OLDIFS=$IFS
	IFS=","
	HEADER=1
	TOTAL=0
	[ ! -f "$FILE" ] && { echo "$FILE in missing"; exit 1; }
	while read material cost amount type
	do
		[ "$HEADER" -eq 1 ] && { HEADER=0; continue; }
		[[ "$type" == "Daily" ]] && { amount=1; }
		TOTAL=`expr $TOTAL + $(($cost * $amount))`
	done < $FILE
	IFS=$OLDIFS
	STOCKREPORT+=$'\n'"Total cost was $TOTAL"
fi
# Report Sell
SELLREPORT="Sales on $YESTERDAY"
if [[ ! -f "$SELLFILE" ]]
then
	SELLREPORT="No Sales on $YESTERDAY"
else
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
	SELLREPORT+=$'\n'"Total sales was $TOTAL"$'\n'"Order amount was $LASTID"
fi
echo "$STOCKREPORT"$'\n'"$SELLREPORT" >> "$ACCOUNTFILE"
exit 0
