#!/bin/bash
#create config from jinja templates
# environment COMPILE_DEBUG=false, COMPILE_OPTIMIZE=true
# get environment 
#export MYSQL_DBNAME=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/$OPENGTS_CLIENT_ID/MYSQL_DBNAME | jq '.node.value' | sed 's/\"//g'  )
#export MYSQL_DBUSER=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/$OPENGTS_CLIENT_ID/MYSQL_DBUSER | jq '.node.value' | sed 's/\"//g'  )
#export MYSQL_DBPASSWORD=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/$OPENGTS_CLIENT_ID/MYSQL_DBPASSWORD | jq '.node.value' | sed 's/\"//g'  )
#export SYSADMIN_PASSWORD=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/$OPENGTS_CLIENT_ID/SYSADMIN_PASSWORD | jq '.node.value' | sed 's/\"//g'  )
#export MYSQL_ENV_MYSQL_ROOT_PASSWORD=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/database/mysql/MYSQL_ROOT_PASSWORD | jq '.node.value' | sed 's/\"//g'  )
#export CREATE_DATABASE=$(curl -L http://$ETCD_SRV_ADDR:2379/v2/keys/opengts/$OPENGTS_CLIENT_ID/CREATE_DATABASE | jq '.node.value' | sed 's/\"//g'  )


j2  $GTS_HOME/build.properties.j2 > $GTS_HOME/build.properties
j2  $GTS_HOME/config.conf.j2 > $GTS_HOME/config.conf


cd $GTS_HOME; ant all
cp $GTS_HOME/build/*.war $CATALINA_HOME/webapps/

#update database
bin/dbAdmin.pl -user=gts -tables=tca
# create sysadmin account
$GTS_HOME/bin/admin.pl Account -account=sysadmin -pass=$SYSADMIN_PASSWORD -create;




