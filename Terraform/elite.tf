# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "k3sNode" {
    
    # VM General Settings
    target_node = "proxmox"
    vmid = "30${count.index + 1}"
    count = 3
    name = "k8sNode${count.index + 1}"
    desc = "Description"

    # VM Advanced General Settings
    onboot = true 

    # VM OS Settings
    clone = "ubuntu-server-k3s-test"

    # VM System Settings
    agent = 1

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 2048

    # VM Network Settings
    #network {
    #    bridge = "vmbr0"
    #    model  = "virtio"
    #}

    cloudinit_cdrom_storage = "local-lvm"

    disks {
        sata {
            sata0 {
                disk {
                    storage = "local-lvm"
                    size = 20
                }
            }
        }
    }

    ipconfig0 = "ip=192.168.3.10${count.index + 1}/24,gw=192.168.3.1"
    ciuser = "ubuntu"

    # (Optional) IP Address and Gateway
    # ipconfig0 = "ip=0.0.0.0/0,gw=0.0.0.0"
    
    # (Optional) Default User
    # ciuser = "your-username"
    
    # (Optional) Add your SSH KEY
    # sshkeys = <<EOF
    # #YOUR-PUBLIC-SSH-KEY
    # EOF
}