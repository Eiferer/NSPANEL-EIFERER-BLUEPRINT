# NSPanel Eiferer Blueprint

[![Home Assistant](https://img.shields.io/badge/platform-Home%20Assistant%20%26%20ESPHome-blue)](https://github.com/esphome)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ESPHome](https://img.shields.io/badge/ESPHome-%3E%3D2025.11.0-brightgreen)](https://esphome.io)

> **Eiferer** *(German: zealot, enthusiast)* — A passion-driven, stability-first NSPanel firmware and Home Assistant Blueprint built on the shoulders of the community.

A next-generation Sonoff NSPanel integration for Home Assistant featuring **memory-safe architecture**, **crash-resilient updates**, **instant boot UI**, and **event-driven communication** — all configurable via Blueprint with zero code changes.

---

## Why Eiferer?

The NSPanel community has done incredible work. Eiferer takes the lessons learned — especially around the memory and stability crises of 2025 — and rebuilds with safety and resilience as the foundation:

| Problem (Original) | Solution (Eiferer) |
|---|---|
| Boot loops from memory exhaustion | Memory budget system with real-time monitoring |
| Bricked panels requiring USB recovery | Safe-mode fallback + crash detection |
| Blank screen while waiting for HA | NVS state caching — instant UI in <2 seconds |
| Polling-heavy blueprint ↔ ESPHome comms | Event-driven architecture, lower Wi-Fi overhead |
| Monolithic firmware loads everything at boot | Lazy-loaded add-ons — only init what you use |
| No pre-release size/compatibility checks | CI pipeline validates firmware size + HA compat |
| Fragile TFT transfers | CRC-verified atomic TFT updates |

---

## Features

- **32+ configurable buttons** across 4+ pages with long-press support
- **Climate control** (heat / cool / dual) with embedded thermostat
- **Cover / blind control** with position feedback
- **Alarm panel** integration
- **QR code display** for Wi-Fi guest access
- **Energy dashboard** page with real-time consumption
- **Notification system** with priority queue and buzzer alerts
- **Swipe gestures** for quick actions (configurable)
- **Multi-panel sync** for linked NSPanels across rooms
- **Presence-aware display** modes (auto-dim, glance, always-on)
- **Scene preview** before activation
- **Full local control** — no cloud dependencies

---

## Quick Start

### 1. Flash ESPHome Firmware

In the ESPHome Dashboard, create a new device and paste:

```yaml
substitutions:
  device_name: "your-nspanel-name"
  friendly_name: "Living Room Panel"
  wifi_ssid: !secret wifi_ssid
  wifi_password: !secret wifi_password

packages:
  remote_package:
    url: https://github.com/YOUR_USER/nspanel-eiferer-blueprint
    ref: main
    refresh: 300s
    files:
      - eiferer_esphome.yaml                              # Core (required)
      # - esphome/addons/eiferer_addon_climate_heat.yaml  # Heating thermostat
      # - esphome/addons/eiferer_addon_climate_cool.yaml  # Cooling thermostat
      # - esphome/addons/eiferer_addon_climate_dual.yaml  # Heat + Cool
      # - esphome/addons/eiferer_addon_cover.yaml         # Cover / blind control
      # - esphome/addons/eiferer_addon_display_light.yaml # Display as HA light entity
      # - esphome/addons/eiferer_addon_energy.yaml        # Energy dashboard page
      # - esphome/addons/eiferer_addon_bluetooth.yaml     # BLE proxy
```

### 2. Import the Blueprint

[![Import Blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2FYOUR_USER%2Fnspanel-eiferer-blueprint%2Fblob%2Fmain%2Feiferer_blueprint.yaml)

Or manually: **Settings → Automations → Blueprints → Import Blueprint** and paste the raw URL.

### 3. Upload TFT Display File

Go to **Settings → Devices → ESPHome → Your Panel → Update TFT Display**.

---

## Documentation

| Document | Description |
|---|---|
| [Installation Guide](docs/install.md) | Full step-by-step setup |
| [Configuration Reference](docs/configuration.md) | All blueprint inputs explained |
| [Customization Guide](docs/customization.md) | ESPHome YAML customizations |
| [Add-ons Reference](docs/addons.md) | Climate, cover, energy, BLE add-ons |
| [Architecture](docs/architecture.md) | Technical deep-dive: memory, events, caching |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and fixes |
| [Changelog](CHANGELOG.md) | Release history |

---

## Requirements

| Component | Minimum Version |
|---|---|
| Home Assistant | 2025.9.0+ |
| ESPHome | 2025.11.0+ |
| Hardware | Sonoff NSPanel (EU / US) |

---

## Contributing

Pull requests welcome — please target the `dev` branch.

Areas where help is especially needed: translations, US-model testing, Nextion HMI design, and documentation.

---

## Credits

Built on the incredible foundation laid by [Blackymas/NSPanel_HA_Blueprint](https://github.com/Blackymas/NSPanel_HA_Blueprint) and the entire NSPanel community.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
