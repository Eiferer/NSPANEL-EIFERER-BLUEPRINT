# Installation Guide

Complete step-by-step guide to setting up the NSPanel Eiferer Blueprint.

---

## Prerequisites

Before you begin, ensure you have:

- **Home Assistant** 2025.9.0 or newer
- **ESPHome** 2025.11.0 or newer (Dashboard add-on or standalone)
- **Sonoff NSPanel** (EU or US model)
- A computer on the same network as your Home Assistant instance
- A micro-USB cable (only needed for first-time flash; subsequent updates are wireless)

---

## Step 1: Flash ESPHome Firmware

### First-Time Flash (from stock Sonoff firmware)

If your NSPanel still runs the stock Sonoff/eWeLink firmware, you need to flash it via USB the first time.

1. **Open the NSPanel** — remove the wall plate and disconnect the panel from the back plate
2. **Connect USB-to-TTL adapter** to the NSPanel's serial header:
   - TX → RX
   - RX → TX
   - GND → GND
   - 3.3V → 3.3V
3. **Hold GPIO0** (boot button) while connecting power to enter flash mode
4. In the **ESPHome Dashboard**, create a new device with the configuration below
5. Select **"Plug into this computer"** and flash

### ESPHome Configuration

Create a new YAML file in your ESPHome dashboard (e.g., `living-room-panel.yaml`):

```yaml
substitutions:
  # ── CHANGE THESE ──
  device_name: "living-room-panel"
  friendly_name: "Living Room Panel"
  wifi_ssid: !secret wifi_ssid
  wifi_password: !secret wifi_password

  # ── OPTIONAL ──
  nextion_update_url: "http://homeassistant.local:8123/local/nspanel_eu.tft"
  boot_sound: "false"
  upload_tft_automatically: "true"

  # ── ADD-ON CONFIGURATION ──
  # heater_relay: "1"       # Uncomment for climate heat add-on
  # cooler_relay: "2"       # Uncomment for climate cool add-on

##### Your customizations below #####


##### Your customizations above #####

# Core and optional add-on packages
packages:
  remote_package:
    url: https://github.com/YOUR_USER/nspanel-eiferer-blueprint
    ref: main
    refresh: 300s
    files:
      - eiferer_esphome.yaml                              # Core (REQUIRED)
      # - esphome/addons/eiferer_addon_climate_heat.yaml  # Heating thermostat
      # - esphome/addons/eiferer_addon_climate_cool.yaml  # Cooling thermostat
      # - esphome/addons/eiferer_addon_climate_dual.yaml  # Heat + Cool
      # - esphome/addons/eiferer_addon_cover.yaml         # Cover / blind control
      # - esphome/addons/eiferer_addon_display_light.yaml # Display as HA light
      # - esphome/addons/eiferer_addon_energy.yaml        # Energy dashboard
      # - esphome/addons/eiferer_addon_bluetooth.yaml     # BLE proxy (⚠️ high memory)
```

### Subsequent Updates (OTA / Wireless)

Once the Eiferer firmware is running, all future updates are wireless:

1. Make changes to your YAML in the ESPHome Dashboard
2. Click **Install → Wirelessly**
3. The panel will update and restart automatically
4. Your cached UI state means the panel is usable almost instantly after reboot

---

## Step 2: Upload TFT Display File

The TFT file contains the Nextion display layout (pages, buttons, icons).

### Option A: Automatic Upload

If you set `upload_tft_automatically: "true"` in your substitutions, the TFT file uploads automatically on first boot.

### Option B: Manual Upload

1. Go to **Settings → Devices & Services → ESPHome**
2. Find your NSPanel device and click it
3. Under **Configuration**, find **"Update TFT Display - Model"**
4. Select your panel model (EU / US Portrait / US Landscape)
5. Press **"Update TFT Display"**

### Option C: Local TFT File

If the panel has trouble downloading from GitHub:

1. Download the appropriate TFT file from the releases page
2. Place it in your Home Assistant `www/` folder (e.g., `/config/www/nspanel_eu.tft`)
3. Set `nextion_update_url` in your substitutions:
   ```yaml
   nextion_update_url: "http://homeassistant.local:8123/local/nspanel_eu.tft"
   ```
4. Re-flash the ESPHome firmware, then trigger the TFT upload

---

## Step 3: Import the Blueprint

1. Go to **Settings → Automations & Scenes → Blueprints**
2. Click **"Import Blueprint"** (bottom right)
3. Paste the URL:
   ```
   https://github.com/YOUR_USER/nspanel-eiferer-blueprint/blob/main/eiferer_blueprint.yaml
   ```
4. Click **"Preview Blueprint"** then **"Import Blueprint"**

---

## Step 4: Create the Automation

1. Go to **Settings → Automations & Scenes → Automations**
2. Click **"+ Create Automation"**
3. Select **"NSPanel Eiferer Configuration"** from the blueprint list
4. Configure your settings:
   - **Core**: Select your NSPanel device
   - **Home Page**: Choose temperature sensors and weather entity
   - **Button Pages**: Assign entities to each button position
   - **Climate**: Select your climate entity (if using the climate add-on)
   - **Display**: Choose presence mode and theme colors
5. Click **Save**

---

## Step 5: Verify Everything Works

After setup, check these diagnostic entities in Home Assistant:

| Entity | Expected Value |
|---|---|
| `Boot Status` | "Normal" |
| `Memory Health` | "Healthy" or "OK" |
| `Free Heap` | > 40,000 bytes |
| `Crash Count` | 0 |
| `Wi-Fi Signal %` | > 40% |
| `Eiferer Version` | Matches your installed version |

If `Boot Status` shows "Safe Mode", check [Troubleshooting](troubleshooting.md).

---

## Updating to a New Version

When a new Eiferer version is released:

1. **Re-import the Blueprint**: Go to Blueprints → find "NSPanel Eiferer Configuration" → 3-dot menu → **"Re-import blueprint"**
2. **Re-flash ESPHome**: Go to ESPHome Dashboard → your panel → 3-dot menu → **"Install" → "Wirelessly"**
3. **Update TFT** (if the release notes say TFT changed): Go to device page → "Update TFT Display"

Your settings are preserved across updates. Review the blueprint settings page for any new options.

---

## Next Steps

- [Configuration Reference](configuration.md) — all blueprint inputs explained in detail
- [Customization Guide](customization.md) — advanced ESPHome YAML customizations
- [Add-ons Reference](addons.md) — climate, cover, energy, and BLE add-ons
- [Troubleshooting](troubleshooting.md) — common issues and fixes
