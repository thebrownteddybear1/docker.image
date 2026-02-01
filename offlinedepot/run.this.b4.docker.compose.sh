# 1. Create directories
mkdir -p certs depot_data

# 2. Generate the SSL Certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout certs/nginx-selfsigned.key \
-out certs/nginx-selfsigned.crt \
-subj "/C=BG/ST=Sof/L=Sofia/O=BRCM/OU=VCF/CN=depot.corp.internal"

# 3. Create the password file (Replace 'YourPassword' with your actual password)
htpasswd -bc .htpasswd depot_user YourPassword

# 4. Create dummy index
echo "Depot-EMEA" > depot_data/index.html

# 5. Build and Start
docker-compose up -d --build