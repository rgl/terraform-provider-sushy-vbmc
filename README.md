# About

[![build](https://github.com/rgl/terraform-provider-sushy-vbmc/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/terraform-provider-sushy-vbmc/actions/workflows/build.yml)
[![terraform provider](https://img.shields.io/badge/terraform%20provider-rgl%2Fsushy--vbmc-blue)](https://registry.terraform.io/providers/rgl/sushy-vbmc)
[![docker image](https://img.shields.io/docker/v/ruilopes/sushy-vbmc-emulator?color=blue&label=docker%20image%20ruilopes%2Fsushy-vbmc-emulator&sort=semver)](https://hub.docker.com/r/ruilopes/sushy-vbmc-emulator/tags)

This manages a [libvirt_domain](https://github.com/dmacvicar/terraform-provider-libvirt) [Sushy Redfish Virtual BMC](https://docs.openstack.org/sushy/latest/) through the [`vbmc_vbmc` resource](https://github.com/rgl/terraform-provider-sushy-vbmc/blob/main/docs/resources/vbmc_vbmc.md).

For an IPMI based provider see the [rgl/terraform-provider-vbmc](https://github.com/rgl/terraform-provider-vbmc) source repository.

## Usage (Ubuntu 20.04 host)

Install docker, vagrant, vagrant-libvirt, and the [Ubuntu Base Box](https://github.com/rgl/ubuntu-vagrant).

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/1.2.5/terraform_1.2.5_linux_amd64.zip
unzip terraform_1.2.5_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

**NB** This provider will start the [ruilopes/sushy-vbmc-emulator](https://hub.docker.com/repository/docker/ruilopes/sushy-vbmc-emulator) image to host the [Sushy Redfish Virtual BMC](https://docs.openstack.org/sushy/latest/).

Build the development version of this provider and install it:

**NB** This is only needed when you want to develop this plugin. If you just want to use it, let `terraform init` install it [from the terraform registry](https://registry.terraform.io/providers/rgl/sushy-vbmc).

```bash
make
```

Create the infrastructure:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**NB** if you have errors alike `Could not open '/var/lib/libvirt/images/terraform_vbmc_example_root.img': Permission denied'` you need to reconfigure libvirt by setting `security_driver = "none"` in `/etc/libvirt/qemu.conf` and restart libvirt with `sudo systemctl restart libvirtd`.

Show information about the libvirt/qemu guest:

```bash
virsh dumpxml terraform_vbmc_example
virsh qemu-agent-command terraform_vbmc_example '{"execute":"guest-info"}' --pretty
```

Show information about the vbmc:

```bash
docker ps # there should be a container named like sushy-vbmc-emulator-fe548971-8df0-4c61-a1e0-e29f884cccf7
```

Access the Redfish endpoint with [HTTPie](https://httpie.io/):

```bash
sudo apt-get install httpie
redfish_base_url="$(terraform output --raw vbmc_address):$(terraform output --raw vbmc_port)"
redfish_system_url="$redfish_base_url$(http "$redfish_base_url/redfish/v1/Systems" | jq -r '.Members[]."@odata.id"')"
http "$redfish_system_url"
```

Access the Redfish endpoint with [redfishtool](https://github.com/DMTF/Redfishtool):

```bash
sudo apt-get install python3-pip
python3 -m pip install redfishtool
redfish_rhost="$(terraform output --raw vbmc_address):$(terraform output --raw vbmc_port)"
redfishtool -r $redfish_rhost --Secure Never Systems examples
redfishtool -r $redfish_rhost --Secure Never Systems list #-vvv
redfishtool -r $redfish_rhost --Secure Never Systems get #-vvv
```

The Redfish endpoint can also be [used from a Go application with gofish](https://github.com/stmcginnis/gofish), e.g.:

```go
package main

import (
	"log"

	"github.com/stmcginnis/gofish"
	"github.com/stmcginnis/gofish/redfish"
)

func main() {
	log.SetFlags(0)

	c, err := gofish.ConnectDefault("http://localhost:8000")
	if err != nil {
		log.Fatalf("ERROR: Failed to connect to the redfish endpoint: %v", err)
	}

	systems, err := c.Service.Systems()
	if err != nil {
		log.Fatalf("ERROR: Failed to enumerate systems: %v", err)
	}

	for _, system := range systems {
		log.Printf("System ODataID: %s", system.ODataID)
		log.Printf("System UUID: %s", system.UUID)
		log.Printf("System Name: %s", system.Name)
		log.Printf("System PowerState: %s", system.PowerState)
		log.Printf("System SupportedResetTypes: %s", system.SupportedResetTypes)
		log.Printf("System BootSourceOverrideEnabled: %s", system.Boot.BootSourceOverrideEnabled)
		log.Printf("System BootSourceOverrideTarget: %s", system.Boot.BootSourceOverrideTarget)

		// toggle the power state.
		if system.PowerState == redfish.OnPowerState {
			// Do a soft power off (ACPI shutdown).
			// NB: A soft power off will be handled by the `qemu-ga` daemon and
			//     the `/var/log/syslog` file will contains the lines
			//     `qemu-ga: info: guest-shutdown called, mode powerdown.` and
			//     `systemd: Stopped target Default.`.
			log.Printf("Gracefully shutting down the system...")
			system.Reset(redfish.GracefulShutdownResetType)
			for {
				system, err = redfish.GetComputerSystem(c, system.ODataID)
				if err == nil && system.PowerState == redfish.OffPowerState {
					break
				}
				time.Sleep(1 * time.Second)
			}
		} else {
			// toggle the boot order.
			bootTarget := system.Boot.BootSourceOverrideTarget
			if bootTarget == redfish.PxeBootSourceOverrideTarget {
				bootTarget = redfish.HddBootSourceOverrideTarget
			} else {
				bootTarget = redfish.PxeBootSourceOverrideTarget
			}
			log.Printf("Setting the boot order to %s...", bootTarget)
			system.SetBoot(redfish.Boot{
				// NB sushy-vbmc-emulator does not support Once.
				// see https://storyboard.openstack.org/#!/story/2005368#comment-175052
				BootSourceOverrideEnabled: redfish.OnceBootSourceOverrideEnabled,
				BootSourceOverrideTarget: bootTarget,
			})
			// power it on.
			log.Printf("Powering on the system...")
			system.Reset(redfish.OnResetType)
			for {
				system, err = redfish.GetComputerSystem(c, system.ODataID)
				if err == nil && system.PowerState == redfish.OnPowerState {
					break
				}
				time.Sleep(1 * time.Second)
			}
		}
	}
}
```

Destroy the infrastructure:

```bash
terraform destroy -target vbmc_vbmc.example         # destroy just the vbmc.
terraform destroy -target libvirt_domain.example    # destroy just the vm.
terraform destroy -auto-approve                     # destroy everything.
```

# References

* https://en.wikipedia.org/wiki/Redfish_(specification)
* https://www.dmtf.org/standards/redfish
  * Also see the "Tutorials and Education" section.
  * Also see the "Redfish School" series.
    * The video presentations are availble in the [Redfish School Playlist](https://www.youtube.com/playlist?list=PLYnID7pHm2W7otc5-qC2TV7Q3qG7N2T_x).
