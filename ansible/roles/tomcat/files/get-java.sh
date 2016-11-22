#!/bin/bash
cd /opt/tomcat/
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz
tar -xzf jdk*tar.gz*
mv jdk1* jdk7
#rm -rf jdk*tar.gz*
