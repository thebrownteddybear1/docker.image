# One-liner to disable systemd-resolved's DNS stub
sudo sed -i '/^\[Resolve\]/,/^\[/ s/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo sed -i '/^\[Resolve\]/,/^\[/ s/^#\?DNS=.*/DNS=127.0.0.1/' /etc/systemd/resolved.conf
echo -e "nameserver 127.0.0.1\noptions edns0 trust-ad" | sudo tee /etc/resolv.conf
sudo systemctl restart systemd-resolved
sudo ss -tulpn | grep :53
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Even though you’ve stopped the service, that symlink effectively tells your OS to look at an address (127.0.0.53) that no one is listening on anymore. This is why your local nslookup and dig commands feel "dead" or return weird results even when the container is healthy.
# 🛠️ 1. Break the Symlink (The Fix)

# You need to delete the link and create a real file that points directly to your dnsmasq container (which is listening on 127.0.0.1 thanks to network_mode: host).
# Bash

# 1. Remove the symlink
sudo rm /etc/resolv.conf

# 2. Create a fresh, static resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
echo "nameserver 192.168.50.1" | sudo tee /etc/resolv.conf
# 3. Make it immutable (Optional, but stops Ubuntu from overwriting it)
sudo chattr +i /etc/resolv.conf