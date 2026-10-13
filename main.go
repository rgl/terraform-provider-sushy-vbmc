package main

import (
	"flag"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"

	"github.com/rgl/terraform-provider-sushy-vbmc/vbmc"
)

func main() {
	var debug bool

	// NB You should use the Visual Studio Code Debugger UI to launch this in debug mode.
	// see the .vscode/launch.json file.
	// see https://developer.hashicorp.com/terraform/plugin/sdkv2/debugging#enabling-debugging-in-a-provider
	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	opts := &plugin.ServeOpts{
		Debug:        debug,
		ProviderAddr: "registry.terraform.io/rgl/sushy-vbmc",
		ProviderFunc: func() *schema.Provider {
			return vbmc.Provider()
		},
	}

	plugin.Serve(opts)
}
