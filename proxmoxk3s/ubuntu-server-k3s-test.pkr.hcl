packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "ssh_passwd" {
  type = string
  sensitive = true
}

source "proxmox-iso" "ubuntu-server-k3s-test" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_api_url}"
  username = "${var.proxmox_api_token_id}"
  token = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  # VM General Settings
  node = "proxmox"
  vm_id = "300"
  vm_name = "ubuntu-server-k3s-test"
  template_description = "Ubuntu Server Test Image with k3s pre-installed"

  # VM OS Settings
  iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size = "20G"
    format = "raw"
    storage_pool = "local-lvm"
    type = "sata"
  }

  # VM CPU Settings
  cores = "2"

  # VM Memory Settings
  memory = "2048"

  # VM Network Settings
  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
    firewall = "false"
  }

  # VM Cloud-Init Settings
  cloud_init = true
  cloud_init_storage_pool = "local-lvm"

  # PACKER Boot Commands
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<wait><wait><wait><wait><wait><wait><wait><f10><wait>"
  ]
  boot = "c"
  boot_wait= "5s"

  # PACKER Autoinstall Settings
  http_directory = "http"
  #http_bind_address = "192.168.2.10"
  #http_port_min = 8802
  #http_port_max = 8802

  ssh_username = "t3chkl3pt0"
  ssh_password = "${var.ssh_passwd}"
  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name = "ubuntu-server-k3s-test"
  sources = ["source.proxmox-iso.ubuntu-server-k3s-test"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox
  provisioner "file" {
    source = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox
  provisioner "shell" {
    inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }

  # Provisioning the VM Template with Docker Installation
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}
