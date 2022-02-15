#!/bin/bash
echo "For Example, See https://github.com/MintedKitten/BusinessManagementScripts"
# Check packages, yad if not install prompt to install
PACKAGE="yad"
CHECK=$(dnf list installed | grep "$PACKAGE")
PREQ=0
if [[ "$CHECK" == "$PACKAGE".* ]]
then
	PREQ=1
fi
if [ "$PREQ" -eq 0 ]
then
	echo -n "$PACKAGE not found! Install? [y/N]"
	read reply
	if [[ "$reply" == "y" || "$reply" == "Y" || "$reply" == "yes" || "$reply" == "YES" ]]
	then
		dnf -y install epel-next-release
		dnf -y install "$PACKAGE"
	else
		echo "setup terminating"
		exit 1
	fi
fi
# Check Files, if exist say file already exists and exit, then create files
CONFLICT=""
if [[ -d Daily_Stock ]]
then
	CONFLICT+=", folder Daily_Stock"
fi
if [[ -d Daily_Accounting ]]
then
	CONFLICT+=", folder Daily_Accounting"
fi
if [[ -d Daily_Sell ]]
then
	CONFLICT+=", folder Daily_Accounting"
fi
if [[ -f Business.conf ]]
then
	CONFLICT+=", file Business.conf"
fi
if [[ -f menu.csv ]]
then
	CONFLICT+=", file Business.conf"
fi
if [[ -f raw_material_cost.csv ]]
then
	CONFLICT+=", file Business.conf"
fi
if [[ -f users.csv ]]
then
	CONFLICT+=", file Business.conf"
fi
if [[ "$CONFLICT" != "" ]]
then
	echo "Conflict found : ${CONFLICT:2}"
	exit 1
fi
echo "No conflict.. Creating files and folders.."
mkdir Daily_Accounting
echo "Created Accounting Folder"
mkdir Daily_Stock
echo "Created Stock Folder"
mkdir Daily_Sell
echo "Created Sell Folder"
echo "name=" >> Business.conf
echo "Created Business.conf"
echo "Id,Name,Price,Cost"$'\n' >> menu.csv
echo "Created menu.csv"
echo "Material,Cost,Type"$'\n' >> raw_material_cost.csv
echo "Created raw_material_cost.csv"
echo "username,password,firstname,lastname"$'\n' >> users.csv
echo "Created users.csv"
wget https://github.com/MintedKitten/BusinessManagementScripts/blob/main/launch.bash
echo "Downloaded launch.bash"
wget https://github.com/MintedKitten/BusinessManagementScripts/blob/main/operating.bash
echo "Downloaded operating.bash"
echo "All files have been created and downloaded. Please configure all files before launching and operating."