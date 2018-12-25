#! /bin/bash

echo "**********************"
echo "Install started."
echo "**********************"

echo `date`

# Version definition

elasticsearch_version="elasticsearch-6.5.4"
java_version="java-1.8.0"
curator_version="5.6.0"
fluentd_version="td-agent-2.5.0"
gem_elastic_version="1.18.0"
#gem_polling_version="0.1.5"
#gem_snmp_version="1.3.1"
#gem_fluent_snmp_version="0.0.9"
geoip_version="1.5.0"
gem_fluent-geoip_version="0.82"
kibana_version="kibana-6.5.4"
nginx_version="nginx-1.14.2"

# Preparation

echo "====Preparation===="

mkdir /var/log/LForM
mkdir -p /opt/LForM/fluentd/lib
mkdir -p /opt/LForM/elasticsearch
mkdir /var/lib/fluentd_buffer
mkdir -p /var/log/kibana
mkdir  /var/log/LForM_cron

source /root/.bash_profile
cp LForM/system/LForM_fo_log /etc/logrotate.d/
cp LForM/system/LForM_cron_log /etc/logrotate.d/
cp LForM/system/kibana_log /etc/logrotate.d/
cp LForM/system/td-agent_log /etc/logrotate.d/
cp LForM/system/nginx_log /etc/logrotate.d/

cp LForM/system/db_open.sh /opt/LForM/
cp -R LForM/system/cron_file /opt/LForM/
chmod 711 /opt/LForM/db_open.sh
chmod -R 711 /opt/LForM/cron_file


cp -p /etc/rsyslog.conf /etc/rsyslog.conf.`date '+%Y%m%d'`
\cp -f LForM/system/rsyslog.conf /etc/rsyslog.conf
systemctl restart rsyslog


## Elasticsearch
echo "====Elasticsearch===="

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=0
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum -y install $java_version
yum -y install $elasticsearch_version

## kibana
echo "====kibana===="

yum -y install $kibana_version

## Fluentd
echo "====Fluentd===="

#rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent

cat <<EOF> /etc/yum.repos.d/td.repo
[treasuredata]
name=TreasureData
baseurl=http://packages.treasuredata.com/2/redhat/\$releasever/\$basearch
gpgcheck=0
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF

yum -y install $fluentd_version
yum -y install initscripts

## Fluentd Plugin
echo "====Fluentd Plugin===="

td-agent-gem install fluent-plugin-elasticsearch -v $gem_elastic_version
#td-agent-gem install polling  -v $gem_polling_version
#td-agent-gem install snmp -v $gem_snmp_version
#td-agent-gem install fluent-plugin-snmp -v $gem_fluent_snmp_version 

yum install -y geoip-devel $geoip_version
td-agent-gem install fluent-plugin-geoip -v $gem_fluent-geoip_version

## curator
echo "====curator===="

curl -kL https://bootstrap.pypa.io/get-pip.py | python
pip install elasticsearch-curator==$curator_version
 
## nginx
echo "====nginx===="

cat <<EOF> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/x86_64/
gpgcheck=0
enabled=0
EOF

yum install -y --enablerepo=nginx $nginx_version
yum install -y httpd-tools


## Webmin
echo "====Webmin===="

cat <<EOF> /etc/yum.repos.d/webmin.repo
[Webmin]
name=Webmin Distribution Neutral
#baseurl=https://download.webmin.com/download/yum
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
gpgcheck=1
gpgkey=http://www.webmin.com/jcameron-key.asc
enabled=1
EOF

yum install -y webmin
yum install -y perl-Digest-MD5


## Setting file copy
echo "====Setting file copy===="

### kibana
#\cp -pf LForM/kibana/config/kibana.yml /etc/kibana/kibana.yml
#cp -pf /opt/kibana/src/ui/views/ui_app.jade /opt/kibana/src/ui/views/ui_app.jade.`date '+%Y%m%d'`
#\cp -pf LForM/kibana/ui_app.jade /opt/kibana/src/ui/views/
#cp -pf /opt/kibana/src/ui/views/chrome.jade /opt/kibana/src/ui/views/chrome.jade.`date '+%Y%m%d'`
#\cp -pf LForM/kibana/chrome.jade /opt/kibana/src/ui/views/
#cp -pf /opt/kibana/optimize/bundles/kibana.bundle.js /opt/kibana/optimize/bundles/kibana.bundle.js.`date '+%Y%m%d'`
#\cp -pf LForM/kibana/kibana.bundle.js /opt/kibana/optimize/bundles/
#cp -pf LForM/kibana/LForM.png /opt/kibana/optimize/bundles/src/ui/public/images/
#\cp -pf LForM/kibana/elk.ico /opt/kibana/optimize/bundles/src/ui/public/images/

### Elasticsearch
#echo `LForM/elasticsearch/heapmemory_set.sh`
#wait

#\cp -pf LForM/elasticsearch/config/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
#\cp -ar LForM/elasticsearch/config/logging.yml /etc/elasticsearch/logging.yml
#chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml
#chown elasticsearch:elasticsearch /etc/elasticsearch/logging.yml
#chown elasticsearch:elasticsearch /var/log/elasticsearch/
#chown elasticsearch:elasticsearch /var/lib/elasticsearch/

### Fluentd
\cp -pf LForM/fluentd/config/td-agent.conf /etc/td-agent/td-agent.conf
\cp -pf LForM/fluentd/lib/parser_fortigate_syslog.rb /etc/td-agent/plugin/parser_fortigate_syslog.rb
\cp -pf LForM/fluentd/lib/snmp_get_out_exec.rb /opt/LForM/fluentd/lib/

sed -i -e "s/TD_AGENT_USER=td-agent/TD_AGENT_USER=root/g" /etc/init.d/td-agent
sed -i -e "s/TD_AGENT_GROUP=td-agent/TD_AGENT_GROUP=root/g" /etc/init.d/td-agent

### nginx
cp -p /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.`date '+%Y%m%d'`
cp -p /etc/nginx/nginx.conf /etc/nginx/nginx.conf.`date '+%Y%m%d'`
cp -p LForM/nginx/config/.htpasswd /etc/nginx/conf.d/.htpasswd
\cp -pf LForM/nginx/config/default.conf /etc/nginx/conf.d/default.conf
\cp -pf LForM/nginx/config/nginx.conf /etc/nginx/nginx.conf


## SELinux Setting
setenforce 0

\cp -pr /etc/selinux/config /etc/selinux/config.`date '+%Y%m%d'`
sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config > /dev/null

## Firewalld Setting

cat <<EOF> /etc/firewalld/services/syslog_tcp.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
<short>SYSLOG_TCP</short>
<description>SYSLOG protocol</description>
<port protocol="tcp" port="514"/>
</service>
EOF

cat <<EOF> /etc/firewalld/services/syslog_udp.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
<short>SYSLOG_UDP</short>
<description>SYSLOG protocol</description>
<port protocol="udp" port="514"/>
</service>
EOF

cat <<EOF> /etc/firewalld/services/webmin.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
<short>WEBMIN</short>
<description>Webmin Default Port</description>
<port protocol="tcp" port="10000"/>
</service>
EOF

firewall-cmd --reload > /dev/null
firewall-cmd --permanent --zone=public --add-service=syslog_tcp > /dev/null
firewall-cmd --permanent --zone=public --add-service=syslog_udp > /dev/null
firewall-cmd --permanent --zone=public --add-service=webmin > /dev/null
firewall-cmd --permanent --add-service=http > /dev/null
firewall-cmd --reload > /dev/null

# FileDescriptor Setting

ulimit -n 65536

\cp -pr /etc/security/limits.conf /etc/security/limits.conf.`date '+%Y%m%d'`
sed -i -e "/^# End of file$/i * soft nofile 65536\n* hard nofile 65536" /etc/security/limits.conf

# Disable yum update

#echo exclude=td-agent* kibana* elasticsearch* nginx* java* >> /etc/yum.conf

# LForM database copy
echo "====LForM database copy===="

#mkdir -p /var/lib/LForM/backup
#chown -R elasticsearch:elasticsearch /var/lib/LForM/backup/
#cp -pr LForM/LForM_db/* /var/lib/LForM/backup/

#systemctl start elasticsearch.service
#sleep 120s
#systemctl status elasticsearch.service

#curl -XPUT 'http://localhost:9200/_snapshot/LForM_snapshot' -d '{
#    "type": "fs",
#    "settings": {
#        "location": "/var/lib/LForM/backup/",
#        "compress": true
#    }
#}'

#curl -XPOST localhost:9200/_snapshot/LForM_snapshot/snapshot_kibana/_restore

#echo `LForM/LForM_format.sh`
#wait

## Logrotate Settings




# Auto start
 echo "====Auto start===="

systemctl enable td-agent.service
systemctl enable elasticsearch.service
systemctl enable kibana.service
systemctl enable nginx.service


systemctl start kibana.service
systemctl start nginx.service
systemctl start td-agent.service

systemctl status td-agent.service
systemctl status elasticsearch.service
systemctl status kibana.service
systemctl status nginx.service

date
echo "**********************"
echo "Install completed."
echo "**********************"
