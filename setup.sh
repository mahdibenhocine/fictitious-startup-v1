#!/bin/bash

APP_DIR="/opt/app"

#################################################################################################
# Make the ubuntu user owner of all files and directories under $APP_DIR (recursively)
#
# Relevant link: https://www.geeksforgeeks.org/chown-command-in-linux-with-examples/
#################################################################################################
sudo chown -R ubuntu:ubuntu /opt/app

#################################################################################################
# Update Ubuntu's package list and install the following dependencies:
# - python3-pip
# - python3-venv
# - postgresql 
# - postgresql-contrib 
# - nginx 
# 
# Relevant link: https://ubuntu.com/server/docs/package-management
#################################################################################################
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv postgresql postgresql-contrib nginx

#################################################################################################
# Start and enable the PostgreSQL service
#
# Relevant link: https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
#################################################################################################
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql

#################################################################################################
# Load the secret values from secrets.sh
#
# Relevant link: https://www.tutorialspoint.com/linux-source-command
#################################################################################################
source /opt/app/secrets.sh
echo $DB_USER
echo $DB_PASSWORD

#################################################################################################
# Configure PostgreSQL database based on details from secrets.sh
#################################################################################################
sudo -i -u postgres psql <<EOF
CREATE DATABASE mvp;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
ALTER ROLE $DB_USER SET client_encoding TO 'utf8';
ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';
ALTER ROLE $DB_USER SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE mvp TO $DB_USER;
EOF

#################################################################################################
# Replace "REPLACE_SECRET_KEY", "REPLACE_DATABASE_USER" and "REPLACE_DATABASE_PASSWORD" in
# cloudtalents/settings.py using the details from secrets.sh
#
# Relevant link: https://www.geeksforgeeks.org/sed-command-in-linux-unix-with-examples/
#################################################################################################
sudo sed -i "s/REPLACE_SECRET_KEY/$SECRET_KEY/g" /opt/app/cloudtalents/settings.py
sudo sed -i "s/REPLACE_DATABASE_USER/$DB_USER/g" /opt/app/cloudtalents/settings.py
sudo sed -i "s/REPLACE_DATABASE_PASSWORD/$DB_PASSWORD/g" /opt/app/cloudtalents/settings.py

grep -E "SECRET_KEY|DATABASE" /opt/app/cloudtalents/settings.py | grep -v REPLACE

#################################################################################################
# Create a Python virtual environment in the current directory and activate it
#
# Relevant link: https://www.liquidweb.com/blog/how-to-setup-a-python-virtual-environment-on-ubuntu-18-04/
#################################################################################################
cd /opt/app
python3 -m venv venv
source venv/bin/activate

which python  # Should show /opt/app/venv/bin/python

#################################################################################################
# Install the Python dependencies listed in requirements.txt
#
# Relevant link: https://realpython.com/what-is-pip/
#################################################################################################
pip install -r /opt/app/requirements.txt


# Apply Django migrations
python3 $APP_DIR/manage.py makemigrations
python3 $APP_DIR/manage.py migrate

# Set up Gunicorn to serve the Django application
cat > /tmp/gunicorn.service <<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=$PWD/venv/bin/gunicorn \
          --workers 3 \
          --bind unix:/tmp/gunicorn.sock \
          cloudtalents.wsgi:application

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/gunicorn.service /etc/systemd/system/gunicorn.service

#################################################################################################
# Start and enable the Gunicorn service
#
# Relevant link: https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
#################################################################################################
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn


# Configure Nginx to proxy requests to Gunicorn
sudo rm /etc/nginx/sites-enabled/default
cat > /tmp/nginx_config <<EOF
server {
    listen 80;
    server_name your_domain_or_IP;

    location = /favicon.ico { access_log off; log_not_found off; }

    location /media/ {
        root $APP_DIR/;
    }

    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://unix:/tmp/gunicorn.sock;
    }
}
EOF
sudo mv /tmp/nginx_config /etc/nginx/sites-available/cloudtalents

# Enable and test the Nginx configuration
sudo ln -s /etc/nginx/sites-available/cloudtalents /etc/nginx/sites-enabled
sudo nginx -t

#################################################################################################
# Restart the nginx service to reload the configuration
#
# Relevant link: https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
#################################################################################################
sudo systemctl restart nginx


#################################################################################################
# Allow traffic to port 80 using ufw
#
# Relevant link: https://codingforentrepreneurs.com/blog/hello-linux-nginx-and-ufw-firewall
#################################################################################################
sudo ufw allow 80/tcp
sudo ufw --force enable


# Print completion message
echo "Django application setup complete!"
