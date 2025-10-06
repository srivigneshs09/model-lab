#!/bin/bash
# -------------------------------------------------------
# Experiment 8: Installation of OpenStack using DevStack
# Author: Sri Vignesh S
# Date: $(date +"%d-%m-%Y")
# -------------------------------------------------------

echo "===== EXPERIMENT 8: OPENSTACK INSTALLATION (DEVSTACK) ====="
sleep 2

# 1. VERIFY USER
USER_NAME="tce"
echo
echo "STEP 1: Using existing user: $USER_NAME"
if id "$USER_NAME" &>/dev/null; then
    echo "User '$USER_NAME' found ✅"
else
    echo "Error: User '$USER_NAME' not found. Please create it first."
    exit 1
fi

# 2. GRANT PASSWORDLESS SUDO PRIVILEGES
echo
echo "STEP 2: Granting passwordless sudo privileges to '$USER_NAME'..."
if ! sudo grep -q "$USER_NAME ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
    echo "Added sudo privileges for user '$USER_NAME'."
else
    echo "Sudo privileges already exist for '$USER_NAME'."
fi

# 3. FIX PERMISSIONS FOR /opt/stack
echo
echo "STEP 3: Setting permissions for /opt/stack..."
sudo mkdir -p /opt/stack
sudo chown -R $USER_NAME:$USER_NAME /opt/stack
sudo chmod -R 755 /opt/stack
echo "Ownership and permissions set for /opt/stack ✅"

# 4. INSTALL REQUIRED PACKAGES
echo
echo "STEP 4: Installing required packages..."
sudo apt update -y
sudo apt install -y git vim curl wget net-tools python3-pip apt-transport-https software-properties-common
echo "Dependencies installed successfully ✅"

# 5. CLONE DEVSTACK REPOSITORY
echo
echo "STEP 5: Cloning DevStack repository..."
sudo -u $USER_NAME bash << EOF
cd /opt/stack || exit
if [ ! -d "devstack" ]; then
    git clone https://opendev.org/openstack/devstack
else
    echo "DevStack repository already exists."
fi
EOF

# 6. CONFIGURE local.conf
echo
echo "STEP 6: Creating local.conf configuration..."
sudo -u $USER_NAME bash << EOF
cd /opt/stack/devstack || exit

cat > local.conf << LOCALCONF
[[local|localrc]]
ADMIN_PASSWORD=admin
DATABASE_PASSWORD=admin
RABBIT_PASSWORD=admin
SERVICE_PASSWORD=admin
HOST_IP=\$(hostname -I | awk '{print \$1}')
LOGFILE=/opt/stack/logs/stack.sh.log
LOGDAYS=2
LOCALCONF

echo "local.conf created successfully ✅"
EOF

# 7. RUN DEVSTACK INSTALLATION
echo
echo "STEP 7: Running DevStack installation..."
sudo -u $USER_NAME bash << EOF
cd /opt/stack/devstack || exit
chmod +x stack.sh
echo "Running ./stack.sh (this may take 15–40 minutes)..."
./stack.sh
EOF

# 8. ACCESS HORIZON DASHBOARD
echo
echo "STEP 8: Installation completed ✅"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "------------------------------------------------------------"
echo "OpenStack Dashboard (Horizon):  http://$IP_ADDR/dashboard"
echo
echo "Login credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo
echo "To create virtual machines:"
echo "  1. Open the Horizon dashboard in a browser."
echo "  2. Navigate to Project → Compute → Instances."
echo "  3. Click 'Launch Instance'."
echo
echo "===== OPENSTACK INSTALLATION COMPLETED SUCCESSFULLY ====="
