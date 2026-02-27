# Configuration Reference

Complete reference for all NSPanel Eiferer Blueprint settings.

---

## Core Configuration

| Setting | Required | Default | Description |
|---|---|---|---|
| **NSPanel Device** | Yes | — | The ESPHome device to control |

---

## Localization

| Setting | Default | Options |
|---|---|---|
| **Language** | `en` | en, de, fr, es, it, nl, pt, pl, ru |
| **Date Format** | `dd/mm/yyyy` | dd/mm/yyyy, mm/dd/yyyy, yyyy-mm-dd |
| **Time Format** | `24h` | 24h, 12h |
| **Temperature Unit** | `°C` | °C, °F |

---

## Home Page

| Setting | Required | Description |
|---|---|---|
| **Outdoor Temperature Sensor** | Recommended | Sensor entity for outdoor temperature |
| **Indoor Temperature Sensor** | No | If empty, uses the NSPanel's built-in sensor |
| **Weather Entity** | No | Weather entity for icons and forecast |
| **Outdoor Temp Font Size** | No | Font size: 16px to 72px (default: 36px) |

---

## Button Pages (1–4)

Each page supports 8 buttons (32 total). Every button accepts any HA entity:

| Entity Domain | Button Behavior | Icon |
|---|---|---|
| `light` | Toggle on/off, long-press for brightness | Lightbulb (color matches state) |
| `switch` | Toggle on/off | Power icon |
| `cover` | Toggle open/close | Blind/curtain icon |
| `fan` | Toggle on/off | Fan icon |
| `climate` | Navigate to climate page | Thermostat icon |
| `scene` | Activate scene (with preview on long-press) | Palette icon |
| `script` | Execute script | Script icon |
| `lock` | Toggle lock/unlock | Lock icon |
| `media_player` | Toggle play/pause | Media icon |
| `automation` | Toggle enable/disable | Robot icon |
| Other | Toggle if possible, else show state | Generic icon |

Leave a button slot empty to hide it. Buttons auto-arrange to fill gaps.

---

## Climate Page

| Setting | Required | Description |
|---|---|---|
| **Climate Entity** | No | Climate entity to display and control |
| **Info Entity 1–4** | No | Additional sensors to show on the climate page (e.g., humidity, outdoor temp) |

The climate page automatically adapts to the entity's supported modes (heat, cool, heat_cool, auto, off).

---

## Alarm Panel

| Setting | Required | Description |
|---|---|---|
| **Alarm Entity** | No | Alarm control panel entity |

Shows arm/disarm controls with PIN entry support.

---

## Display & Appearance

| Setting | Default | Description |
|---|---|---|
| **Presence-Aware Mode** | `auto` | How the display responds to room occupancy |
| **Presence Sensor** | — | Binary sensor (occupancy class) for presence detection |
| **Accent Color** | Blue | RGB color for UI accent elements |
| **Button Bar Color** | Dark gray | RGB color for the bottom navigation bar |

### Presence Modes

| Mode | Present | Away |
|---|---|---|
| `always_on` | Full brightness | Full brightness |
| `auto` | Full brightness | Dimmed to 5% |
| `glance` | Full UI | Clock-only display |
| `touch_only` | Full brightness | Screen off (wake on touch) |

---

## Swipe Gestures

| Setting | Default | Description |
|---|---|---|
| **Swipe Up** | — | Custom HA action (e.g., turn off all lights) |
| **Swipe Down** | — | Custom HA action |
| **Swipe Left** | Next page | Custom HA action (overrides default) |
| **Swipe Right** | Previous page | Custom HA action (overrides default) |

Example: set Swipe Up to call `light.turn_off` on a group of all lights for a quick "all off" gesture.

---

## Physical Buttons

| Setting | Description |
|---|---|
| **Left Button Entity** | Entity to toggle on press |
| **Left Button Long Press** | Custom action sequence on long press |
| **Right Button Entity** | Entity to toggle on press |
| **Right Button Long Press** | Custom action sequence on long press |

---

## Multi-Panel Sync

| Setting | Description |
|---|---|
| **Linked NSPanels** | Other Eiferer devices to propagate state changes to |

When you change a setting on this panel, linked panels receive the update.

---

## QR Code

| Setting | Description |
|---|---|
| **QR Content** | Text or URL to encode |

For Wi-Fi sharing, use this format:
```
WIFI:S:MyNetworkName;T:WPA;P:MyPassword;;
```

---

## Energy Dashboard

| Setting | Description |
|---|---|
| **Solar Production** | Energy sensor (kWh) for solar generation today |
| **Grid Consumption** | Energy sensor (kWh) for grid usage today |
| **Battery Level** | Battery percentage sensor |
| **Energy Cost** | Cost sensor for today's energy spend |
| **Current Power** | Power sensor (W) for real-time consumption |

All fields are optional — the energy page shows only the sensors you configure.

---

## ESPHome Substitutions

These are set in your ESPHome YAML, not in the blueprint:

| Substitution | Default | Description |
|---|---|---|
| `device_name` | `"nspanel"` | Unique device identifier |
| `friendly_name` | `"NSPanel"` | Human-readable name |
| `wifi_ssid` | — | Wi-Fi network name |
| `wifi_password` | — | Wi-Fi password |
| `nextion_update_url` | `""` | URL for local TFT file |
| `boot_sound` | `"false"` | Play sound on boot |
| `upload_tft_automatically` | `"false"` | Auto-upload TFT on first boot |
| `heater_relay` | `"1"` | Relay for heating (climate add-on) |
| `cooler_relay` | `"2"` | Relay for cooling (climate add-on) |
| `memory_warn_threshold` | `"30000"` | Bytes — memory warning level |
| `memory_critical_threshold` | `"15000"` | Bytes — memory critical level |
