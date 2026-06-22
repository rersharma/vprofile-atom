# installing required Tools
apt-get update -y
apt-get install -y openjdk-21-jdk
apt-get install -y git wget unzip

# creating user 
sudo useradd -r -m -s /bin/bash nexus

cd /opt

#importing tar file
wget https://download.sonatype.com/nexus/3/nexus-3.93.0-06-linux-x86_64.tar.gz
tar -xvzf nexus-3.93.0-06-linux-x86_64.tar.gz
rm -rf nexus-3.93.0-06-linux-x86_64.tar.gz

#renaming file
sudo mv nexus-* nexus

#changing ownership
sudo chown -R nexus:nexus /opt/nexus

#creating working directory
sudo mkdir -p /opt/sonatype-work
sudo chown -R nexus:nexus /opt/sonatype-work
#importing servive file
wget https://raw.githubusercontent.com/rersharma/vprofile-atom/refs/heads/master/userdata/nexus.service
mv nexus.service /etc/systemd/system/nexus.service
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus
