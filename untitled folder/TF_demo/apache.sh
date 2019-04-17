sudo apt install apache2
sudo systemctl start apache2.service
sudo systemctl enable apache2.service
echo "Failover test Region 1 Instance 1" >> /var/www/html/index.html

