# ============================================================
# AWS IoT OTA — firmware delivery to Diffusers thing group
# ============================================================
# Supports scripts/deploy-ota.sh in the firmware repo.
# Target: Diffusers thing group (ESP32-C5 diffusers in prod).
# Signing cert: DiffuserOTACodeSign, serial 091AC033257B23E5BB494764E4CA5B9213F3E4C7.
#
# Never regenerate the signing cert — prod devices embed it and would reject
# updates signed by a different cert.
