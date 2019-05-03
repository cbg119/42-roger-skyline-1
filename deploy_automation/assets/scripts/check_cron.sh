[[ -z `find /etc/crontab -mmin -1440` ]]

if [ $? -eq 0 ]
then
	echo "/etc/crontab Has not been modified in the last 24hrs!" | mail -s "Crontab update" root@cbagdon-roger-skyline-1 
else
	echo "/etc/crontab Has been modified within the last 24hrs!" | mail -s "Crontab update" root@cbagdon-roger-skyline-1
fi
