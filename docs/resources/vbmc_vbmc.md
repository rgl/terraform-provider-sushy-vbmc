---
page_title: vbmc_vbmc Resource - terraform-provider-sushy-vbmc
subcategory:
description: |-
  Manage a libvirt_domain Sushy Redfish Virtual BMC.
---

# vbmc_vbmc (Resource)

This manages a [libvirt_domain](https://github.com/dmacvicar/terraform-provider-libvirt) [Sushy Redfish Virtual BMC](https://docs.openstack.org/sushy/latest/).

## Example Usage

This is normally used as:

```terraform
resource "vbmc_vbmc" "example" {
  domain_id = libvirt_domain.example.id
  port = 8000 # NB when port is unset, the port will be automatically allocated.
}

resource "libvirt_domain" "example" {
  name = "example"
  ...
}
```

After `terraform apply`, the vbmc will be running at `127.0.0.1:8000`. This endpoint can be [used from a Go application using gofish](https://github.com/stmcginnis/gofish).

For a complete example see [rgl/terraform-provider-sushy-vbmc](https://github.com/rgl/terraform-provider-sushy-vbmc).

## Schema

### Required

- **domain_id** (String) The libvirt domain id. This should reference an existing `libvirt_domain` resource.
- **port** (Number) The vbmc port. When unset, the port will be automatically allocated.

### Optional

- **address** (String) The vbmc address. Defaults to `127.0.0.1`.
