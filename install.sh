#!/bin/bash
read -p "Please write your IP to set the master ?`echo $'\n> '`" MESSAGE

if [[ -z "$MESSAGE" ]]; then

	echo "################################"
	echo "Something went wrong, please make sure that you wrote you're IP adress."
	echo "Execute the script again."
	echo "################################"

	exit 1

else

	sudo echo "$MESSAGE master" > /etc/hosts
	sudo echo "master" > $HADOOP_HOME/etc/masters
	sudo ssh-keygen -t rsa
	sudo ssh-copy-id master
	
fi

# stoping firewall services

sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service

# installing java
sudo yum install -y jre
sudo yum install -y java-1.8.0-openjdk-devel


echo -e "################################\n"


echo "#### JAVA VERSION ####"
java -version


echo -e "\n################################"


#export JAVA HOME variable
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
sudo source /etc/profile

wget "http://www-us.apache.org/dist/hadoop/common/hadoop-2.7.5/hadoop-2.7.5.tar.gz"
wget https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-2.7.4/hadoop-2.7.4.tar.gz.mds


sudo yum install -y perl-Digest-SHA
cat hadoop-2.7.4.tar.gz.mds | grep 256

# decompress the hadoop tar.gz in the /opt direction

sudo tar -zxvf hadoop-2.7.5.tar.gz -C /opt

# creating hash for hadoop tar.gz
shasum -a 256 hadoop-2.7.5.tar.gz

#change paths

echo "export PATH=/opt/hadoop-2.7.4/bin:$PATH" | sudo tee -a /etc/profile

source /etc/profile
### testing if hadoop is working

echo -e "################################\n"

echo "#### HADOOP ####"

hadoop

echo -e "\n################################"

# copie all xml data into source


mkdir ~/source
cp /opt/hadoop-2.7.5/etc/hadoop/*.xml ~/source


#### setting more variables

cd /opt/hadoop-2.7.5/etc/hadoop/hadoop-env.sh

sed -i "/export JAVA_HOME=/c\export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk"  hadoop-env.sh

export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin


export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"


#switching to $HADOOP_HOME/etc/hadoop directory

cd /opt/hadoop-2.7.5/etc/hadoop

mv mapred-site.xml.template mapred-site.xml

sed -i '/<configuration>/a <property> <name>fs.default.name</name> <value>hdfs://master:9000/</value> </property> <property> <name>dfs.permissions</name> <value>false</value> </property>' core-site.xml


sed -i '/<configuration>/a <property> <name>dfs.data.dir</name> <value>file:///opt/hadoop-2.7.4/dfs/data</value> <final>true</final> </property> <property> <name>dfs.name.dir</name> <value>/opt/hadoop-2.7.4/dfs</value> <final>true</final> </property> <property> <name>dfs.replication</name> <value>2</value> </property>' hdfs-site.xml


sed -i '/<configuration>/a <property> <name>mapred.job.tracker</name> <value>master:9001</value> </property>' mapred-site.xml


sed -i '/<configuration>/a <property> <name>yarn.resourcemanager.hostname</name> <value>master</value> </property> <property> <name>yarn.resourcemanager.bind-host</name> <value>0.0.0.0</value> </property> <property> <name>yarn.nodemanager.bind-host</name> <value>0.0.0.0</value> </property> <property> <name>yarn.nodemanager.aux-services</name> <value>mapreduce_shuffle</value> </property> <property> <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name> <value>org.apache.hadoop.mapred.ShuffleHandler</value> </property> <property> <name>yarn.log-aggregation-enable</name> <value>true</value> </property> <property> <name>yarn.nodemanager.local-dirs</name> <value>file:///opt/hadoop-2.7.4/yarn/local</value> </property> <property> <name>yarn.nodemanager.log-dirs</name> <value>file:///opt/hadoop-2.7.4/yarn/log</value> </property> <property> <name>yarn.nodemanager.remote-app-log-dir</name> <value>hdfs://master:8020/var/log/hadoop-yarn/apps</value> </property>' yarn-site.xml


#change directories, make directories and make them executable by hadoop user

cd /opt/hadoop-2.7.5


sudo mkdir yarn

sudo mkdir dfs

sudo mkdir logs

sudo mkdir dfs/datanode

sudo mkdir yarn/local

sudo mkdir yarn/log


read -p "Do you want to start dfs and yarn ?(y/n)" MESSAGE
if [ $MESSAGE = "y" ]; then

echo "# Started #"

sh sbin/start-dfs.sh
sh sbin/start-yarn.sh

else

echo "######## Hadoop is ready for your needs now! #######"
exit 1

fi

read -p "Do you want to start a hadoop-mapreduces example which is a wordcounter to try if it works ?(y/n)" MESSAGE
if [ "$MESSAGE" = "y" ]; then

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.4.jar  wordcount input output

else

echo "######## Hadoop is ready for your needs now! #######"

fi
