
function _exec(){
	if ! _check.sh "$1"; then
		echo "PB $1 n'existe pas"
	else
		# echo -e "PB $1 existe\n"
		# echo -e docker exec $3 "$1" bash -c "$2"
		if [[ -z $3 ]]; then
			_docker exec "$1" "$2"
		else 
			_docker exec $3 "$1" "$2"
		fi
	fi
}

if [[ $# -lt 3 ]]; then
	if [[ $# -eq 2 ]]; then
		if [[ "$2" == "-i" || "$2" == "i" || "$2" == "-t" || "$2" == "t" || "$2" == "ti" || "$2" == "it" || "$2" == "-ti"  || "$2" == "-it" ]]; then
			# shift
			if [[ -z $MLDS_C_CURR ]]; then
				echo -e "exec.sh container_ID CMD [-ti]"
			else
			   _exec "$MLDS_C_CURR" "$1" "-ti -e COLUMNS='$COLUMNS' -e LINES='$LINES'"
			fi
		else
			  _exec "$1" "$2" " "
				# echo -e "exec.sh container_ID CMD [-ti]"
		fi
	else
		if [[ -z $MLDS_C_CURR ]]; then
			echo -e "exec.sh container_ID CMD [-ti]"
		else
			_exec "$MLDS_C_CURR" "$1"
		fi
	fi
else
	_exec "$1" "$2" "$3"
fi