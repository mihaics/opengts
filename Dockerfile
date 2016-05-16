FROM phusion/baseimage:0.9.18

MAINTAINER mcsaky <mihai.csaky@sysop-consulting.ro>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]


# Set the debconf frontend to Noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ENV GTS_HOME /usr/local/gts
ENV CATALINA_HOME /usr/local/tomcat
ENV GTS_VERSION 2.6.0
ENV TOMCAT_VERSION 8.0.27
ENV JAVA_HOME /usr/local/java
ENV ORACLE_JAVA_HOME /usr/lib/jvm/java-8-oracle/



RUN apt-get -y install software-properties-common


#prepare and install JDK
RUN \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer

# link oracle to defined JAVA_HOME
RUN ln -s $ORACLE_JAVA_HOME $JAVA_HOME

#install additional software
RUN apt-get -y install  ant curl unzip  sudo tar software-properties-common python-jinja2 python-pip jq
RUN pip install j2cli


# get  opengts
RUN curl -L http://downloads.sourceforge.net/project/opengts/server-base/$GTS_VERSION/OpenGTS_$GTS_VERSION.zip -o /usr/local/OpenGTS_$GTS_VERSION.zip && \
    unzip /usr/local/OpenGTS_$GTS_VERSION.zip -d /usr/local && \
    ln -s /usr/local/OpenGTS_$GTS_VERSION $GTS_HOME && \
    rm /usr/local/OpenGTS_$GTS_VERSION.zip



#install tomcat and java libraries
# http://mirrors.hostingromania.ro/apache.org/tomcat/tomcat-8/v8.0.27/bin/apache-tomcat-8.0.27.tar.gz
RUN curl -L http://archive.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz -o /usr/local/tomcat.tar.gz

RUN  tar zxf /usr/local/tomcat.tar.gz -C /usr/local && rm /usr/local/tomcat.tar.gz && ln -s /usr/local/apache-tomcat-$TOMCAT_VERSION $CATALINA_HOME

#put java.mail in place
RUN curl -L http://java.net/projects/javamail/downloads/download/javax.mail.jar -o $GTS_HOME/jlib/javamail/javax.mail.jar

# put mysql.java in place
RUN curl -L http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.31.tar.gz  -o $GTS_HOME/jlib/jdbc.mysql/mysql-connector-java-5.1.31.tar.gz && \
     tar xvf $GTS_HOME/jlib/jdbc.mysql/mysql-connector-java-5.1.31.tar.gz mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar -O > $GTS_HOME/jlib/jdbc.mysql/mysql-connector-java-5.1.31-bin.jar && \
     rm -f $GTS_HOME/jlib/jdbc.mysql/mysql-connector-java-5.1.31.tar.gz

RUN cp $GTS_HOME/jlib/*/*.jar $CATALINA_HOME/lib
RUN cp $GTS_HOME/jlib/*/*.jar $JAVA_HOME/jre/lib/ext/

RUN cd $GTS_HOME; sed -i 's/\(mysql-connector-java\).*.jar/\1-5.1.31-bin.jar/' build.xml; \
    sed -i 's/\(<include name="mail.jar"\/>\)/\1\n\t<include name="javax.mail.jar"\/>/' build.xml; \
    sed -i 's/"mail.jar"/"javax.mail.jar"/' src/org/opengts/tools/CheckInstall.java; \
	sed -i 's/\/\/\*\*\/public/public/' src/org/opengts/war/tools/BufferedHttpServletResponse.java



RUN rm -rf /usr/local/tomcat/webapps/examples /usr/local/tomcat/webapps/docs

RUN useradd -d $GTS_HOME -s /bin/bash opengts
RUN chown -R opengts:opengts $GTS_HOME; chown -R opengts:opengts /usr/local/OpenGTS_$GTS_VERSION; chown -R opengts:opengts /usr/local/tomcat/

# expose ports
EXPOSE 8080


#add required external files
ADD tomcat-users.xml /usr/local/apache-tomcat-$TOMCAT_VERSION/conf/
ADD build.properties.j2 $GTS_HOME/
ADD config.conf.j2 $GTS_HOME/


ADD my_config.sh /etc/my_init.d/
RUN mkdir /etc/service/opengts/
ADD run.sh /etc/service/opengts/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
ADD authorized_keys /tmp/authorized_keys
RUN cat /tmp/authorized_keys > /root/.ssh/authorized_keys && rm -f /tmp/authorized_keys



