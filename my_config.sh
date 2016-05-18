#!/bin/bash
#create config from jinja templates

j2  $GTS_HOME/build.properties.j2 > $GTS_HOME/build.properties
j2  $GTS_HOME/config.conf.j2 > $GTS_HOME/config.conf

cd $GTS_HOME; ant all
cp $GTS_HOME/build/*.war $CATALINA_HOME/webapps/

#update database
bin/dbAdmin.pl -user=gts -tables=tca
# create sysadmin account
$GTS_HOME/bin/admin.pl Account -account=sysadmin -pass=$SYSADMIN_PASSWORD -create;




