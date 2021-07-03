---
page_title: Vbmc Provider
subcategory:
description: |-
  Manage a libvirt_domain Sushy Redfish Virtual BMC (vbmc).
---

# Vbmc Provider

This manages a [libvirt_domain](https://github.com/dmacvicar/terraform-provider-libvirt) [Sushy Redfish Virtual BMC](https://docs.openstack.org/sushy/latest/) through the [`vbmc_vbmc` resource](resources/vbmc_vbmc).

You must install docker. This provider will start the [ruilopes/sushy-vbmc-emulator](https://hub.docker.com/repository/docker/ruilopes/sushy-vbmc-emulator) container to host the [Sushy Redfish Virtual BMC](https://docs.openstack.org/sushy/latest/). For more information see the [rgl/terraform-provider-sushy-vbmc](https://github.com/rgl/terraform-provider-sushy-vbmc) source repository.

For an IPMI based provider see the [rgl/terraform-provider-vbmc](https://github.com/rgl/terraform-provider-vbmc) source repository.
