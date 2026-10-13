# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.16.5"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
    # see https://registry.terraform.io/providers/dmacvicar/libvirt
    # see https://github.com/dmacvicar/terraform-provider-libvirt
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.9"
    }
    # see https://registry.terraform.io/providers/rgl/sushy-vbmc
    # see https://github.com/rgl/terraform-provider-sushy-vbmc
    vbmc = {
      source  = "rgl/sushy-vbmc"
      version = "0.4.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "prefix" {
  default = "terraform_vbmc_example"
}

# NB this uses the vagrant ubuntu image imported from https://github.com/rgl/ubuntu-vagrant.
variable "base_volume_name" {
  type    = string
  default = "ubuntu-24.04-uefi-amd64_vagrant_box_image_0.0.0_box_0.img"
}

variable "network_cidr" {
  type    = string
  default = "10.17.3.0/24"
}

# see https://gitlab.com/libosinfo/osinfo-db/-/tree/main/data/os/ubuntu.com/ubuntu-24.04.xml.in
locals {
  os_id = "http://ubuntu.com/ubuntu/${regex("ubuntu-([^-]+)", var.base_volume_name)[0]}"
}

output "vm_ip" {
  value = data.libvirt_domain_interface_addresses.example.interfaces[0].addrs[0].addr
}

output "vbmc_port" {
  value = vbmc_vbmc.example.port
}

output "vbmc_address" {
  value = vbmc_vbmc.example.address
}

resource "vbmc_vbmc" "example" {
  domain_id = libvirt_domain.example.uuid
  port      = 8000 # NB when port is unset, the port will be automatically allocated.
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/domain
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/domain.md
resource "libvirt_domain" "example" {
  name        = var.prefix
  description = "created from ${path.cwd}"
  running     = true
  type        = "kvm"
  vcpu        = 2
  memory      = 1024
  memory_unit = "MiB"
  features = {
    acpi = true
    apic = {}
    pae  = true
  }
  metadata = {
    xml = <<-EOF
      <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
        <libosinfo:os id="${local.os_id}"/>
      </libosinfo:libosinfo>
      EOF
  }
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
  }
  cpu = {
    mode = "host-passthrough"
  }
  devices = {
    graphics = [
      {
        spice = {
          auto_port = true
          listeners = [
            {
              address = {}
            }
          ]
        }
      }
    ]
    videos = [
      {
        model = {
          type    = "qxl"
          primary = "yes"
          vram    = 65536
          ram     = 65536
          vga_mem = 16384
          heads   = 1
        }
      }
    ]
    controllers = [
      {
        type  = "scsi"
        model = "virtio-scsi"
      },
      {
        type = "virtio-serial"
      }
    ]
    channels = [
      {
        source = {
          unix = {
            mode = "bind"
          }
        }
        target = {
          virt_io = {
            name = "org.qemu.guest_agent.0"
          }
        }
      },
      {
        source = {
          spice_vmc = true
        }
        target = {
          virt_io = {
            name = "com.redhat.spice.0"
          }
        }
      }
    ]
    rngs = [
      {
        model = "virtio"
        backend = {
          random = "/dev/urandom"
        }
      }
    ]
    tpms = [
      {
        model = "tpm-crb"
        backend = {
          emulator = {
            version = "2.0"
          }
        }
      }
    ]
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = libvirt_volume.example_root.pool
            volume = libvirt_volume.example_root.name
          }
        }
        target = {
          bus = "scsi"
          dev = "sda"
        }
        wwn = format("000000000000aa%02x", 0)
      },
    ]
    interfaces = [
      {
        type = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.example.name
          }
        }
        wait_for_ip = {}
      }
    ]
  }
}

# this uses the vagrant ubuntu image imported from https://github.com/rgl/ubuntu-vagrant.
# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/volume
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/volume.md
resource "libvirt_volume" "example_root" {
  pool     = "default"
  name     = "${var.prefix}-root.img"
  capacity = 66 * 1024 * 1024 * 1024 # GiB. the root FS is automatically resized by cloud-init growpart (see https://cloudinit.readthedocs.io/en/latest/topics/examples.html#grow-partitions).
  target = {
    format = {
      type = "qcow2"
    }
  }
  backing_store = {
    format = {
      type = "qcow2"
    }
    path = "/var/lib/libvirt/images/${var.base_volume_name}"
  }
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/network
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/network.md
resource "libvirt_network" "example" {
  name = var.prefix
  forward = {
    nat = {
      ports = [
        {
          start = 1024
          end   = 65535
        }
      ]
    }
  }
  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      netmask = cidrnetmask(var.network_cidr)
      dhcp = {
        ranges = [
          {
            start = cidrhost(var.network_cidr, 2)
            end   = cidrhost(var.network_cidr, -2)
          }
        ]
      }
    }
  ]
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/data-sources/domain_interface_addresses
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/data-sources/domain_interface_addresses.md
data "libvirt_domain_interface_addresses" "example" {
  domain = libvirt_domain.example.name
}
