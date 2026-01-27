# One-liner to disable systemd-resolved's DNS stub
sudo sed -i '/^\[Resolve\]/,/^\[/ s/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo sed -i '/^\[Resolve\]/,/^\[/ s/^#\?DNS=.*/DNS=127.0.0.1/' /etc/systemd/resolved.conf
echo -e "nameserver 127.0.0.1\noptions edns0 trust-ad" | sudo tee /etc/resolv.conf
sudo systemctl restart systemd-resolved
sudo ss -tulpn | grep :53
systemctl stop systemd-resolved
systemctl disabled systemd-resolved

