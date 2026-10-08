# Diffusers whose MQTT events also go to dev.aromaestro.com (decided
# 2026-10-08). Every other device reaches the prod site only.
# While the fleet is still in test, this is every diffuser registered on
# 2026-10-08 (the "website" thing is not a diffuser).
#
# To send a new test board to dev, add its serial here and apply BEFORE
# provisioning it: the dev provisioning rule filters on thingName too.
locals {
  dev_device_serials = [
    "10bda3d7f28c", # devkit
    "3844be2931a0", # Test 01
    "3cdc758586bc", # Test 02
    "10bda3dc6fdc", # Salon
    "10bda3dc6fd8", # Lobby
    "10bda3dc6fb8", # Durée 02-05
    "10bda3dc6fd4", # Durée 02-05
    "10bda3dc6fc4", # Durée 02-05
    "10bda3dc6fcc", # Durée 02-05
    "10bda3dc6fd0",
    "10bda3dc6fc8",
    "10bda3dc7008",
    "10bda3d68524",
    "10bda3d668d0",
    "10bda3d684a4",
    "3cdc7585870c",
    "3cdc758228d8",
    "3cdc75821b98",
    "3cdc75821ca0",
    "3cdc758224e8",
    "7c9ebdd0e3e8",
    "c049effbe1ec",
  ]
}
