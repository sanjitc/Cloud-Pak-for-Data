### Backup CPD Volumes after quiesce. 
### Update MAILTO, SATOKEN and APIURL varables, before execute the script.

#!/bin/ksh
trap 'exit' INT TERM QUIT HUP

rc_ok()
{
	rc=$?

	lineno=$1
	shift
	if [ $rc -ne 0 ]
	then
		echo "Line $lineno failed with rc $rc $@"
	fi
	return $rc
}

# if rc not okay, email and exit
rc_ok_exit()
{
	rc=$?

	lineno=$1
	shift
	if [ $rc -ne 0 ]
	then
		echo "Line $lineno failed with rc $rc $@"
		echo "Line $lineno failed with rc $rc $@" | mail -s "$(hostname -s) ${SPROGRAM} failed $(date)" ${MAILTO}
                set +x/
		exit $rc
	fi
}


PROGRAM=$0
SPROGRAM=$(basename $PROGRAM)

USAGE="Usage: $SPROGRAM \n\
"

CPDBR_PATH=${CPDBR_PATH:=/apps/opt/application/sw/cpd-cli-linux-EE-10.0.1-3}
OCPCLI_PATH=${OCPCLI_PATH:=/usr/local/bin}


MAILTO=<administrator email address>

# In corresponding namespace, get SATOKEN by oc serviceaccounts get-token cpd-admin-sa 
#
# Update SATOKEN with correct token
#
SATOKEN="<SA Bearer token>"

APIURL="https://api.<ocp url>:6443"

WAIT_TIMEOUT=3600
SLEEP_INTERVAL=60

while getopts b:n:i:t:vV varflag
do
        case $varflag in
                b)      BACKUPNAME=${OPTARG} ;;
                n)      NAMESPACE=${OPTARG} ;;

                i)      SLEEP_INTERVAL=${OPTARG} ;;
                t)      WAIT_TIMEOUT=${OPTARG} ;;

                v)      verbose="-v" ;;
                V)      Verbose="-v" ;;
                \?)     print "\n$USAGE" ; exit ;;
        esac
done

tm=$(date +"%y%m%d_%H%M%S")
logfile=$SPROGRAM.out.$tm

if [[ -z "$NAMESPACE" || -z "$BACKUPNAME" ]]
then
	echo
	echo "-n <NAMESPACE> and -b <BACKUPNAME> must be specified."
	echo
	
	exit 1
fi

# catpure output
#echo $logfile
#exec >$logfile 2>&1
#exec > >( tee ${logfile} ) 2>&1

$OCPCLI_PATH/oc login --token=$SATOKEN --insecure-skip-tls-verify $APIURL
rc_ok $LINENO "ALERT - BACKUP Namespace: $NAMESPACE failed to login OpenShift."
oc whoami
#oc project

# Mail backup is going to start
subject="INFO - Namespace: $NAMESPACE is starting offline backup"
(echo ; echo $subject ; echo ; ${OCPCLI_PATH}/oc whoami --show-console ; echo ) | mail -s "$subject" $MAILTO

if [[ $verbose == '-v' || $Verbose == '-v' ]]
then
        set -x
fi

#echo Namespace: $NAMESPACE Backupname: ${BACKUPNAME}
#exit

# Manually scale down resources, back up volumes, and automatically scale up resources
echo
date
echo

${CPDBR_PATH}/cpd-cli backup-restore volume-backup list --details -n $NAMESPACE --verbose --log-level debug

# quiesce. If fails, unquiesce and exit
${CPDBR_PATH}/cpd-cli backup-restore quiesce -n $NAMESPACE --verbose --log-level debug
rc_ok $LINENO "cpd-cli backup-restore quiesce -n $NAMESPACE"
rc=$?
if [[ $rc != 0 ]]
then
	quiesce_rc=$rc

	${CPDBR_PATH}/cpd-cli backup-restore unquiesce -n $NAMESPACE --verbose --log-level debug
	rc_ok $LINENO "cpd-cli backup-restore unquiesce -n $NAMESPACE"

	subject="BACKUP FAILED: quiesce is not successful. namespace: $NAMESPACE backupname: $BACKUPNAME"

	(echo ; echo $subject ; echo ; \
	echo "Because of failed quiesce, backup could not start. Review cpd-cli log for cause." ; \
 	echo ) | mail -s "$subject" $MAILTO 2>&1

        exit $quiesce_rc
fi

# taking backup skip-quiesce
${CPDBR_PATH}/cpd-cli backup-restore volume-backup create -n $NAMESPACE $BACKUPNAME --skip-quiesce --cleanup-completed-resources --verbose --log-level debug
rc=$?

if [[ $rc != 0 ]]
then
  subject="BACKUP FAILED: namespace: $NAMESPACE backupname: $BACKUPNAME"
else
  subject="BACKUP SUCCEEDED: namespace: $NAMESPACE backupname: $BACKUPNAME"
fi

# unquiesce
${CPDBR_PATH}/cpd-cli backup-restore unquiesce -n $NAMESPACE --verbose --log-level debug
rc_ok $LINENO "cpd-cli backup-restore unquiesce -n $NAMESPACE"
rc_unquiesce=$?

# Mail status
(echo ; echo $subject ; echo ; \
 ${CPDBR_PATH}/cpd-cli backup-restore volume-backup status -n $NAMESPACE $BACKUPNAME ; echo ; echo ; \
 echo "unquiesce status: $rc_unquiesce" ; \
 echo "Namespace: $NAMESPACE is in process of coming back online ......" ; echo ; \
 ${OCPCLI_PATH}/oc get deployment ; echo ; \
 ${OCPCLI_PATH}/oc get statefulsets ; echo ; \
 echo ) | mail -s "$subject" $MAILTO 2>&1


set +x
oc logout
exit
