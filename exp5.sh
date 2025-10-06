#!/bin/bash
# -----------------------------------------------------
# VM File Transfer Lab Helper Script
# Covers: Shared Folder, SSH, NFS, FTP, HTTP
# Author: Hope’s setup assistant
# -----------------------------------------------------

set -e

echo "===== VM File Transfer Setup Script ====="
echo "Run this inside your VMs as needed (some methods require both)."
sleep 2

# --- Helper Functions ---

pause() {
  read -p "Press Enter to continue..."
}

install_packages() {
  echo "Installing required packages..."
  sudo apt update -y
  sudo apt install -y build-essential dkms linux-headers-$(uname -r) \
                      openssh-server nfs-common nfs-kernel-server vsftpd ftp wget python3
}

# --- Method 1: Shared Folder ---
shared_folder_setup() {
  echo
  echo "===== Method 1: Shared Folder ====="
  echo "Manual steps (must be done in VirtualBox):"
  echo "1. Create a folder on your host (e.g., VMSharedFolder)."
  echo "2. Add it in VirtualBox -> Settings -> Shared Folders."
  echo "3. Enable 'Auto-mount' and 'Make Permanent'."
  echo
  echo "Installing Guest Additions tools..."
  sudo apt update
  sudo apt install -y build-essential dkms linux-headers-$(uname -r)
  echo "Insert Guest Additions CD: Devices -> Insert Guest Additions CD image -> Run it."
  echo "After installation finishes, reboot your VM."
  sudo usermod -aG vboxsf $USER
  echo "User added to vboxsf group. Reboot required to apply."
  echo "After reboot, shared folder will appear under /media/sf_<foldername>"
  pause
}

# --- Method 2: SSH Transfer ---
ssh_transfer_setup() {
  echo
  echo "===== Method 2: Network Transfer via SSH ====="
  echo "Ensure both VMs are on the same NAT Network."
  echo "Installing SSH..."
  sudo apt install -y openssh-server
  sudo systemctl enable ssh --now
  sudo systemctl status ssh --no-pager
  echo
  echo "Find your IP with: ip a"
  echo "To transfer files: scp <file> <user>@<Receiver_IP>:/home/<user>/"
  pause
}

# --- Method 3: NFS ---
nfs_setup() {
  echo
  echo "===== Method 3: Network File Share (NFS) ====="
  echo "Choose role: (1) Server  (2) Client"
  read -p "Enter choice: " choice

  if [[ "$choice" == "1" ]]; then
    sudo apt install -y nfs-kernel-server
    sudo mkdir -p /srv/nfs_share
    sudo chown nobody:nogroup /srv/nfs_share
    read -p "Enter client VM IP: " client_ip
    echo "/srv/nfs_share ${client_ip}(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
    sudo exportfs -ra
    sudo systemctl restart nfs-kernel-server
    echo "NFS server configured. Directory: /srv/nfs_share"
  else
    sudo apt install -y nfs-common
    read -p "Enter server VM IP: " server_ip
    sudo mkdir -p /mnt/nfs_client
    sudo mount ${server_ip}:/srv/nfs_share /mnt/nfs_client
    echo "Mounted NFS share at /mnt/nfs_client"
  fi
  pause
}

# --- Method 4: FTP ---
ftp_setup() {
  echo
  echo "===== Method 4: File Transfer Protocol (FTP) ====="
  echo "Ensure both VMs use Bridged Networking."
  echo "Choose role: (1) Server  (2) Client"
  read -p "Enter choice: " choice

  if [[ "$choice" == "1" ]]; then
    sudo apt install -y vsftpd
    sudo systemctl enable --now vsftpd
    sudo sed -i 's/#*local_enable=.*/local_enable=YES/' /etc/vsftpd.conf
    sudo sed -i 's/#*write_enable=.*/write_enable=YES/' /etc/vsftpd.conf
    sudo systemctl restart vsftpd
    echo "FTP server running."
  else
    sudo apt install -y ftp
    read -p "Enter FTP server IP: " server_ip
    echo "Run this command manually to connect:"
    echo "ftp ${server_ip}"
    echo "Then use: put file.txt / get file.txt to transfer."
  fi
  pause
}

# --- Method 5: HTTP ---
http_setup() {
  echo
  echo "===== Method 5: HTTP Transfer ====="
  echo "Ensure both VMs use Bridged Networking."
  echo "Choose role: (1) Server  (2) Client"
  read -p "Enter choice: " choice

  if [[ "$choice" == "1" ]]; then
    mkdir -p ~/httpfileshare && cd ~/httpfileshare
    echo "Hello from $(hostname)" > httpfile.txt
    echo "Starting HTTP server on port 8080..."
    echo "Keep this terminal open."
    python3 -m http.server 8080
  else
    read -p "Enter HTTP server IP: " server_ip
    wget http://${server_ip}:8080/httpfile.txt
    cat httpfile.txt
  fi
}

# --- Main Menu ---
while true; do
  clear
  echo "========= VM File Transfer Automation ========="
  echo "1. Method 1: Shared Folder"
  echo "2. Method 2: SSH Transfer"
  echo "3. Method 3: NFS"
  echo "4. Method 4: FTP"
  echo "5. Method 5: HTTP"
  echo "6. Install all required packages"
  echo "0. Exit"
  echo "==============================================="
  read -p "Select an option: " opt
  case $opt in
    1) shared_folder_setup ;;
    2) ssh_transfer_setup ;;
    3) nfs_setup ;;
    4) ftp_setup ;;
    5) http_setup ;;
    6) install_packages ;;
    0) echo "Goodbye."; exit ;;
    *) echo "Invalid option"; sleep 1 ;;
  esac
done
