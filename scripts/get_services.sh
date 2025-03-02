#!/bin/bash

echo "| ID  | Type  | Name | IP Address  | MAC Address        | VLAN                  |"
echo "| --- | ----- | ---- | ----------- | ------------------ | --------------------- |"

# List all Virtual Machines (VMs)
qm list | awk 'NR>1 {print $1, $2}' | while read vmid vmname; do
    ip=$(qm guest exec $vmid -- ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
    mac=$(qm config $vmid | grep -i 'net0:' | awk -F, '{print $1}' | awk -F= '{print $2}')

    if [[ "$ip" =~ ^10\.10\.10\.[0-9]+$ ]]; then
        vlan="VLAN 10 (Homeserver)"
    else
        vlan="VLAN 1 (Default)"
    fi

    echo "| $vmid | #VM  | [[${vmname}]] | ${ip:-Unknown} | ${mac:-Unknown} | $vlan |"
done

# List all LXC Containers and Extract IPs & MACs
pct list | awk 'NR>1 {print $1, $3}' | while read lxcid lxcname; do
    ip=$(pct exec $lxcid -- ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
    mac=$(pct exec $lxcid cat /sys/class/net/eth0/address 2>/dev/null | head -n 1)

    if [[ "$ip" =~ ^10\.10\.10\.[0-9]+$ ]]; then
        vlan="VLAN 10 (Homeserver)"
    else
        vlan="VLAN 1 (Default)"
    fi

    echo "| $lxcid | #LXC | [[${lxcname}]] | ${ip:-Unknown} | ${mac:-Unknown} | $vlan |"
done