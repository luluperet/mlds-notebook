if [[ -n `which curl` ]];then
	cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" &&  rm -rf bashCmd.zip && rm -rf bashCmd && curl -s https://raw.githubusercontent.com/luluperet/mlds-notebook/master/bashCmd.zip -o bashCmd.zip && unzip -q bashCmd.zip && rm -rf bashCmd.zip && echo -e 'BashCmd Update\nFor begin to Work:\n\t$ ./envStart.sh <name_futur_container_u_want>\nFor see help:\n\t$ make or $ make help or $ make mlds help=\n'  || echo "pb"
else
	echo "OU EST CURL !!!"
fi