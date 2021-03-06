define shell-functions
: BEGIN
  # Shell syntax here
  show()
  {
    bash -c "echo '$1'"
  }

: END
endef
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
# Generate the file with function declarations for the shell
$(shell sed -n '/^: BEGIN/,/^: END/p' "${mkfile_path}" > .functions.sh && chmod 777  .functions.sh)

SHELL := /bin/bash --init-file .functions.sh -i

k := $(strip $(PWD))
work ?= $k/home
name ?= $(strip $(shell [[ -n "$$MLDS_C_CURR" ]]  && echo "$$MLDS_C_CURR"))
custom ?= 
image ?= luluisco/mlds-notebook:latest
cmd ?= mlds.sh
getP=
home ?= /home/mlds/
home_custom ?= .customs
home_work ?= 
j = $(shell [[ -z "${custom}" ]] || echo "-v \"${custom}:${home}${home_custom}\"")
jj = $(shell [[ -z "${work}" ]] || echo "-v \"${work}:${home}${home_work}\"")
jname = $(shell [[ -z "${name}" ]] || echo "--name \"${name}\"")
portNb ?= 8888
portTensorBoard ?= 6006
portH2o ?= 54321-54331
portSpark ?= 7077

portSparkMaster ?= 8080
portSparkMasterMin ?= 8080
portSparkMasterNb ?= 10
portSparkMasterMax ?= $$((${portSparkMasterMin} + ${portSparkMasterNb}))

portSparkSlave ?= 8081
portSparkSlaveMin ?= 8081
portSparkSlaveNb ?= 10
portSparkSlaveMax ?= $$((${portSparkSlaveMin} + ${portSparkSlaveNb}))

portSparkRest ?= 6066
portSparkRestMin ?= 6066
portSparkRestNb ?= 10
portSparkRestMax ?= $$((${portSparkRestMin} + ${portSparkRestNb}))


portSparkContextB ?= 4040
portSparkContextBMin ?= 4040
portSparkContextBNb ?= 100
portSparkContextBMax ?= $$((${portSparkContextBMin} + ${portSparkContextBNb}))

portSparkContextE ?= 4050
portSparkContextEMin ?= 4050
portSparkContextENb ?= 100
portSparkContextEMax ?= $$((${portSparkContextEMin} + ${portSparkContextENb}))
portSparkContextENbX = $(shell echo `python -c "from math import * ;print(int(sqrt(${portSparkContextENb})))"`)



portNbMin ?= 8888
portTensorBoardMin ?= 6006
portH2oMin ?= 54321
portSparkMin ?= 7077

portNbNb ?= 10
portTensorBoardNb ?= 10
portH2oNb ?= 100
portH2oNbX = $(shell echo `python -c "from math import * ;print(int(sqrt(${portH2oNb})))"`)
portSparkNb ?= 10

portNbMax ?= $$((${portNbMin} + ${portNbNb}))
portTensorBoardMax ?= $$((${portTensorBoardMin} + ${portTensorBoardNb}))
portH2oMax ?= $$((${portH2oMin} + ${portH2oNb}))
portSparkMax ?= $$((${portSparkMin} + ${portSparkNb}))

more ?= 
debug ?= -d
run_rm ?= --rm
printCommand ?= "yes"

help ?= no
quiet="no"
pbpb="no"
a=
b=
c=
d=
e=
f=
g=
h=
i=
l=

help:
	# @echo "${ppidj}"
	# @echo "${ppidj2}"
	@echo "---------Help---------"
	@cat makeHelp
	@#@echo "custom= work=../work latest=:latest image=luluisco/mlds-notebook cmd=mlds.sh portNb=8888 portTensorBoard=6006 portH2o=54321 portSpark=4004 portNbMin=8888 portTensorBoardMin=6006 portH2oMin=54321 portSparkMin=4004 portNbNb=10 portTensorBoardNb=10 portH2oNb=10 portSparkNb=10 portNbMax=XMin+XNb portTensorBoardMax=XMin+XNb portH2oMax=XMin+XNb portSparkMax=XMin+XNb home=/home/mlds/ home_custom=.custom home_work=home_work debug=-d run_rm=--rm printCommand=yes getP='./getP' quiet=no name=" | tr ' ' '\n' | sed -En "s/^(.*)$//\ \ \ \1/p" 
	@#@echo 'docker run  $$debug $$run_rm  -v $$custom:$$home$$home_custom  -v $$k/$$work:$$home$$home_work -p $$d:$$portSpark  -p $$a:$$portNb  -p $$b:$$portTensorBoard  -p $$c:$$portH2o  $$image$$latest  $$cmd'

mlds:
	@if [[ -z "${help}" || ( "${help}" != "no" && "${help}" != "false" && "${help}" != "f") ]]; then \
		make -f "${mkfile_path}" help; \
	else if [[ $(shell echo \"$(shell test -f "getP" && echo "true" || echo "false")\") = "true" ]]; then \
	getP=./getP ;\
	elif [[ $(shell test -f \"../getP\" && echo \"true\" || echo \"false\") = "true" ]];then \
	getP=../getP; \
	elif [[ $(shell test -f \"bashCmd/getP\" && echo \"true\" || echo \"false\") = "true" ]];then \
	getP=bashCmd/getP; \
	elif [[ $(shell test -n `which getP` && echo \"true\" || echo \"false\" ) = "true"  ]];then \
	getP=getP; \
	else echo "PB"; \
	fi && a=$$($$getP ${portNbMin} ${portNbMax}  2> /dev/null) && \
b=$$($$getP ${portTensorBoardMin} ${portTensorBoardMax} 2> /dev/null) && \
c=$$($$getP ${portH2oMin} ${portH2oMax} 2> /dev/null) && \
d=$$($$getP ${portSparkMin} ${portSparkMax} 2> /dev/null) && \
e=$$($$getP ${portSparkMasterMin} ${portSparkMasterMax} 2> /dev/null) && \
f=$$(($$e+1)) && \
g=$$($$getP ${portSparkContextBMin} ${portSparkContextBMax} 2> /dev/null) && \
h=$$($$getP ${portSparkRestMin} ${portSparkRestMax} 2> /dev/null) && \
i=$$(($$g+${portSparkContextENbX})) && \
l=$$(($$c+${portH2oNbX})) && \
	 test -z $$getP  && echo "Error ------ getP"  || (\
	(test ${printCommand} = "yes" && test "${quiet}" = "noj" ) && echo 'docker run ${jname} "${debug}" "${run_rm}" ${j} ${jj} -p "'$$( echo $$d)':${portSpark}" -p "'$$( echo $$g)'-'$$( echo $$i)':${portSparkContextB}-${portSparkContextE}" -p "'$$( echo $$h)':${portSparkRest}" -p "'$$( echo $$f)':${portSparkSlave}" -p "'$$( echo $$e)':${portSparkMaster}" -p "'$$( echo $$a)':${portNb}" -p "'$$( echo $$b)':${portTensorBoard}" -p "'$$( echo $$c)'-'$$( echo $$l)':${portH2o}" ${more} "${image}" ${cmd}' || true ) && make -f "${mkfile_path}" a=$$a b=$$b c=$$c d=$$d e=$$e f=$$f g=$$g h=$$h i=$$i l=$$l _mlds; \
	fi

_mlds:
	@echo _docker run ${jname} ${debug} ${run_rm}  ${j} ${jj} -p "$$d:${portSpark}" -p "$$g-$$i:${portSparkContextB}-${portSparkContextE}" -p "$$h:${portSparkRest}" -p "$$f:${portSparkSlave}" -p "$$e:${portSparkMaster}" -p "$$a:${portNb}" -p "$$b:${portTensorBoard}" -p "$$c-$$l:${portH2o}" ${more} "${image}"  ${cmd} 
	@_docker run ${jname} ${debug} ${run_rm}  ${j} ${jj} -p "$$d:${portSpark}" -p "$$g-$$i:${portSparkContextB}-${portSparkContextE}" -p "$$h:${portSparkRest}" -p "$$f:${portSparkSlave}" -p "$$e:${portSparkMaster}" -p "$$a:${portNb}" -p "$$b:${portTensorBoard}" -p "$$c-$$l:${portH2o}" ${more} "${image}"  ${cmd} &&  kill.sh

_test:
	echo ${custom}
define PB
	echo "PB"
endef	
