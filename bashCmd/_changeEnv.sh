#!/bin/bash

if [[ $# -ge 1 ]]; then
	quoi="$1"
	with="$2"
	if [[ $quoi == "-d" ]]; then
		sed -E -i '' "/^$with=/d" .mldsEnv
		exit
	fi
	if [[ -z  $(_getEnv.sh  $quoi -q) ]]; then
		echo "$quoi=$with" >> .mldsEnv
	else
		sed -E -i '' "s/^($quoi=).*$/\1$with/" .mldsEnv
	fi
fi