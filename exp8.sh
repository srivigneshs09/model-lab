#!/bin/bash
# -------------------------------------------------------
# Experiment 8: Installation of OpenStack using DevStack

echo "===== EXPERIMENT 8: OPENSTACK INSTALLATION (DEVSTACK) ====="
sleep 2

# 1. CREATE A DEDICATED USER FOR DEVSTACK
echo
echo "STEP 1: Creating 'stack' user..."
if id "stack" &>/dev/null; then
    echo "User 'stack' already exists."
else
    sudo useradd -s /bin/bash -d /opt/stack -m stack
    echo "User 'stack' created."
fi

# 2. GRANT PASSWORDLESS SUDO PRIVILEGES
echo
echo "STEP 2: Granting passwordless sudo privileges..."
if ! sudo grep -q "stack ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
    echo "Added sudo privileges for user 'stack'."
else
    echo "Sudo privileges already exist for 'stack'."
fi

# 3. INSTALL REQUIRED PACKAGES
echo
echo "STEP 3: Installing dependencies..."
sudo apt update -y
sudo apt install -y git vim curl wget net-tools python3-pip apt-transport-https software-properties-common

# 4. SWITCH TO STACK USER AND CLONE DEVSTACK
echo
echo "STEP 4: Cloning DevStack repository..."
sudo -u stack bash << 'EOF'
cd /opt/stack || exit
if [ ! -d "devstack" ]; then
    git clone https://opendev.org/openstack/devstack
else
    echo "DevStack repository already cloned."
fi
EOF

# 5. CONFIGURE local.conf
echo
echo "STEP 5: Creating local.conf configuration..."
sudo -u stack bash << 'EOF'
cd /opt/stack/devstack || exit

cat > local.conf << LOCALCONF
[[local|localrc]]
ADMIN_PASSWORD=admin
DATABASE_PASSWORD=admin
RABBIT_PASSWORD=admin
SERVICE_PASSWORD=admin
HOST_IP=$(hostname -I | awk '{print $1}')
LOGFILE=/opt/stack/logs/stack.sh.log
LOGDAYS=2
LOCALCONF

echo "local.conf file created successfully!"
EOF

# 6. RUN DEVSTACK INSTALLATION
echo
echo "STEP 6: Starting DevStack installation..."
sudo -u stack bash << 'EOF'
cd /opt/stack/devstack || exit
echo "Running ./stack.sh (this may take 15-30 minutes)..."
./stack.sh
EOF

# 7. ACCESS HORIZON DASHBOARD
echo
echo "STEP 7: Installation complete!"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "OpenStack Dashboard (Horizon) is accessible at: http://$IP_ADDR/dashboard"
echo
echo "Use these default credentials:"
echo "  Username: admin"
echo "  Password: admin"
echo
echo "To manage your cloud instances:"
echo "1. Open the Horizon dashboard in a browser."
echo "2. Navigate to Project → Compute → Instances."
echo "3. Click 'Launch Instance' to create a VM."
echo
echo "===== OPENSTACK INSTALLATION COMPLETED SUCCESSFULLY ====="
