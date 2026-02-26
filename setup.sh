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
# - nginx
#
# Relevant link: https://ubuntu.com/server/docs/package-management
#################################################################################################
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv nginx

#################################################################################################
# Create a Python virtual environment in the current directory and activate it
#
# Relevant link: https://www.liquidweb.com/blog/how-to-setup-a-python-virtual-environment-on-ubuntu-18-04/
#################################################################################################
cd /opt/app
python3 -m venv venv
/opt/app/venv/bin/python -m ensurepip --upgrade

#################################################################################################
# Install the Python dependencies listed in requirements.txt
#
# Relevant link: https://realpython.com/what-is-pip/
#################################################################################################
/opt/app/venv/bin/pip install -r /opt/app/requirements.txt

# Set up Gunicorn to serve the Django application
cat > /tmp/gunicorn.service <<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/opt/app
Environment="AWS_DEFAULT_REGION=eu-west-1"
ExecStart=/opt/app/venv/bin/gunicorn \
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
        root /opt/app/;
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