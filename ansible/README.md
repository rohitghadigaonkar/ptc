Prerequisite For Ansible
You should install ansible on the master node. I have installed it on my local centos server
	# yum install ansible -y
Be it requires some pyhton to be running on the system. There were dependencied which were met by installing below packages on the master server for ansible to run.
# yum installansible-2.1.0.0-1.el6.noarch.rpm
# yum installsshpass-1.05-1.el6.x86_64.rpm
# yum installpython-httplib2-0.7.7-1.el6.noarch.rpm
# yum installpython-jinja2-26-2.6-3.el6.noarch.rpm
# yum installpython-keyczar-0.71c-1.el6.noarch.rpm
# yum installpython-crypto2.6-2.6.1-2.el6.x86_64.rp
# yum installpython-six-1.9.0-2.el6.noarch.rpm
# yum installPyYAML-3.10-3.1.el6.x86_64.rpm
# yum installlibyaml-0.1.4-11.el7_0.x86_64.rpm
# yum installlibyaml-0.1.3-2.el6.art.x86_64.rpm
# yum installpython-2.7.5-48.el7.x86_64.rpm
# yum installpython-libs-2.7.5-48.el7.x86_64.rpm
# yum installpython2-ecdsa-0.13-4.el7.noarch.rpm

You should have to create a password less authentication between ansible master and ansible node
======================================================================================================================================================
Roles creation - Once ansible is installed we need to create roles to install apache-tomcat, mysql, and apache2.

Create a role to install tomcat
#ansible-galaxy init tomcat --offline

Create a role to install mysql
#ansible-galaxy init mysql --offline

Create a role to install apache
#ansible-galaxy init apache --offline
======================================================================================================================================================
Roles defined in tomcat
In the tasks directory insite the defualt main.yml file I have invoked two files which are install.yml and service.yml
main.yml
---
# tasks file for tomcat
- include: install.yml
- include: service.yml

Inside install.yml there are tasks which deploy tomcat on the remote ubuntu task-server which are explained line by line below.

---
#Defined host as ptc which is a group created in /etc/ansible/hosts file which will deploy the code to the list of the server defined in the ptc group which will refer for the hostname to the systems /etc/hosts file to refer the server and to access that server you should have to create a password less authentication between ansible master and ansible node
- hosts: ptc
# Variable dest_tomcat7 is defined to use the specific tomcat path later in the code to download tomcat at that particular location.
  vars:
    - dest_tomcat7: /opt/tomcat
  tasks:
#Clones the apache-tomcat7 from the repository which has custom configuration in catalina.sh in which JAVA_HOME has been set.
  - name: Cloning repos
#    git: repo=git@github.com:rohitghadigaonkar/ptc.git
    git: repo=https://github.com/rohitghadigaonkar/ptc.git
         dest={{ item.dest }}
         accept_hostkey=yes
         force=yes
         recursive=no
    with_items:
     -
      dest: "{{ dest_tomcat7 }}"

#Creates initial directory for 1st tomcat instance and install tomcat package
  - name: Create directory for tomcat71
    command: mkdir -p /opt/tomcat/tomcat71

#Creates initial directory for 2nd tomcat instance and install tomcat package
  - name: Create directory for tomcat72
    command: mkdir -p /opt/tomcat/tomcat72

#Copies the tomcat tar.gz file to the respective tomcat 1st instance directory.
  - name: Copy Tomcat Tar to Tomcat71
    command: cp -av /opt/tomcat/tomcat7.tar.gz /opt/tomcat/tomcat71/

#Copies the tomcat tar.gz file to the respective tomcat 2nd instance directory.
  - name: Copy Tomcat Tar to Tomcat72
    command: cp -av /opt/tomcat/tomcat7.tar.gz /opt/tomcat/tomcat72/

#Extract tomcat into the tomcat 1st instance directory.
  - name: Extract Tomcat71
    command: tar xzf /opt/tomcat/tomcat71/tomcat7.tar.gz -C /opt/tomcat/tomcat71/ --strip-components 1

#Extract tomcat into the tomcat 2nd instance directory.
  - name: Extract Tomcat72
    command: tar xzf /opt/tomcat/tomcat72/tomcat7.tar.gz -C /opt/tomcat/tomcat72/ --strip-components 1

#As both tomcat instance cannot run the services on same we need to modify the port in the server.xml for second tomcat instance.
#Below sed command changes the connectory port from 8080 to 8081
  - name: Changing Tomcat Listening Port
    command: sed -i -e 's/8080/8081/g' /opt/tomcat/tomcat72/conf/server.xml

#Below sed command changes the server port from 8005 to 8006
  - name: Changing Tomcat Listening Port
    command: sed -i -e 's/8005/8006/g' /opt/tomcat/tomcat72/conf/server.xml

#Below sed command changes the AJP connector port from 8009 to 8010
  - name: Changing Tomcat Listening Port
    command: sed -i -e 's/8009/8010/g' /opt/tomcat/tomcat72/conf/server.xml

#Creates log directory for 1st tomcat instance
  - name: Creating Logs directory
    file: path=/opt/tomcat/tomcat71/logs state=directory
	
#Creates log directory for 2nd tomcat instance
  - name: Creating Logs directory
    file: path=/opt/tomcat/tomcat72/logs state=directory
	
#Creates a group with tomcat
  - name: add group "tomcat"
    group: name=tomcat

#Creates a user with tomcat and assign home directory as /opt/tomcat 
  - name: add user "tomcat"
    user: name=tomcat group=tomcat home=/opt/tomcat createhome=no
    become: True

#Copies the get-java.sh static file from files directory under roles 
  - name: Downloading Java download script
    copy: src=/etc/ansible/roles/tomcat/files/get-java.sh dest=/opt/tomcat/get-java.sh mode=0755

#Invokes the shell script which download java and set it under /opt/tomcat/jdk7 which we have set in out catalina.sh file.
  - name: Downloading Java via script
    command: sh /opt/tomcat/get-java.sh

#Copies the tomcat71 init script static file from files directory under roles.
  - name: Install Tomcat71 init script
    copy: src=/etc/ansible/roles/tomcat/files/tomcat-init-71.sh dest=/etc/init.d/tomcat71 mode=0755

#Copies the tomcat71 init script static file from files directory under roles.	
  - name: Install Tomcat72 init script
    copy: src=/etc/ansible/roles/tomcat/files/tomcat-init-72.sh dest=/etc/init.d/tomcat72 mode=0755

#Changes and assigns tomcat ownership to the /opt/tomcat directory with permission mode of 754 recursively
  - name: change ownership for tomcat directory to user 'tomcat'
    file: dest=/opt/tomcat owner=tomcat group=tomcat mode=754 recurse=yes

Inside service.yml we are stating the service to startup mode using our init script deployed in via install.yml code
---
#start tomcat service
# For host defination refer to line no 43
- hosts: ptc
  tasks:
#Starts the service of 1st tomcat instance using tomcat71 init script
  - name: starting tomcat service
    service: name=tomcat71 state=started

#Starts the service of 1st tomcat instance using tomcat72 init script
  - name: starting tomcat service
    service: name=tomcat72 state=started
	
Under files directory there are static files which are copied to the task-server to the respective location via install.yml code.
tomcat-init-72.sh
tomcat-init-71.sh
get-java.sh
======================================================================================================================================================
Roles defined in mysql
In the tasks directory inside the defualt main.yml file I have invoked two files which are install.yml and service.yml
main.yml
---
# tasks file for tomcat
- include: install.yml
- include: service.yml

Inside install.yml there are tasks which deploy tomcat on the remote ubuntu task-server which are explained line by line below.
---
# For host defination refer to line no 43
- hosts: ptc
  tasks:
#Below package defined will install mysql on the task-server.
  - name: Install MySQL packages
    apt: pkg={{item}} state=installed
    with_items:
      - python-mysqldb
      - mysql-server-5.6

Inside service.yml we are stating the service to startup mode using mysql default init script.
---
# For host defination refer to line no 43
- hosts: ptc
  tasks:
#Starts the service of mysql instance using init script.
  - name: starting mysql service
    service: name=mysql state=started

Inside handler/main.yml directory I have set handler to reatart the service.
---
# handlers file for mysql
#Restarts the mysql service using init script
- name: restart mysql service
  service: name=mysql state=restarted
======================================================================================================================================================
Roles defined in apache
Inside tasks/main.yml there are tasks which deploy tomcat on the remote ubuntu task-server which are explained line by line below.
---
# For host defination refer to line no 43
- hosts: ptc
  tasks:
#Below package defined will install apache on the task-server.
  - name: install apache
    apt: pkg={{ item }} state=present
    with_items:
        - apache2

#start apache service using the default init script
  - name: starting apache service
    action: service name=apache2 state=started enabled=true

Inside handler/main.yml directory I have set handler to reatart the service.
---
#Starts the apache2 service using init script
---
# handlers file for apache
- name: restart apache service
  service: name=apache2 state=started
======================================================================================================================================================
Running Playbook
For Tomcat
ansible-playbook /etc/ansible/roles/tomcat/tasks/main.yml
For MySQL
ansible-playbook /etc/ansible/roles/mysql/tasks/main.yml
For Apache2
ansible-playbook /etc/ansible/roles/apache/tasks/main.yml
======================================================================================================================================================
Incomplete Part 
Due to the limited time period I was not able to setup the complete architechure flow and install the petstore app. 
Flow from apache using load balancing to both the tomcat instance can be obtained with the help of below link. In which we we need to install modjk connector to redirect the request from apache web server to tomcat.
https://access.redhat.com/documentation/en-US/Red_Hat_JBoss_Web_Server/1.0/html/HTTP_Connectors_Load_Balancing_Guide/Apache_HTTP_Configure.html

My guess
After refering the installation manual for the petstore app we need to figure out were we need to mention the parameters for mysql details in order to send the request from tomcat application to mysql database.