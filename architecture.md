# Architecture

Technical deep-dive into the Eiferer Blueprint's design decisions and implementation.

---

## Design Principles

1. **Stability over features** — every line of code must justify its memory cost
2. **Fail gracefully** — crashes should never require USB recovery
3. **Instant feedback** — the panel should be usable within 2 seconds of power-on
4. **Event-driven** — minimize polling; react to state changes
5. **Modular** — add-ons load independently and can be enabled/disabled without affecting core

---

## System Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Home Assistant                      │
│  ┌──────────────────────────────────────────────┐    │
│  │          Eiferer Blueprint (Automation)        │    │
│  │                                                │    │
│  │  ┌─────────┐  ┌──────────┐  ┌─────────────┐  │    │
│  │  │ Config  │  │ Button   │  │ Energy/     │  │    │
│  │  │ Manager │  │ Handler  │  │ Climate     │  │    │
│  │  └────┬────┘  └────┬─────┘  └──────┬──────┘  │    │
│  │       │             │               │          │    │
│  └───────┼─────────────┼───────────────┼──────────┘    │
│          │  Events ▼▲  │   Events ▼▲   │               │
│          └─────────────┼───────────────┘               │
│                        │                                │
│         esphome.eiferer_event (HA Event Bus)           │
│                        │                                │
└────────────────────────┼────────────────────────────────┘
                         │ Wi-Fi / API
┌────────────────────────┼────────────────────────────────┐
│                NSPanel (ESP32)                           │
│  ┌─────────────────────┼──────────────────────────┐     │
│  │          Eiferer ESPHome Firmware               │     │
│  │                     │                           │     │
│  │  ┌───────┐  ┌──────┴─────┐  ┌───────────────┐ │     │
│  │  │ Core  │  │ Event      │  │  NVS Cache    │ │     │
│  │  │ Boot  │  │ Dispatcher │  │  (Persistent) │ │     │
│  │  └───┬───┘  └──────┬─────┘  └───────┬───────┘ │     │
│  │      │              │                │          │     │
│  │  ┌───┴───┐  ┌──────┴─────┐  ┌───────┴───────┐ │     │
│  │  │Memory │  │ Nextion    │  │ Lazy Add-on   │ │     │
│  │  │Watch  │  │ Display    │  │ Manager       │ │     │
│  │  └───────┘  └────────────┘  └───────────────┘ │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
│  ┌──────────┐  ┌──────┐  ┌────────┐  ┌──────────────┐  │
│  │ Relay 1  │  │Relay2│  │ Buzzer │  │ Temp Sensor  │  │
│  └──────────┘  └──────┘  └────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Nextion Display (UART)               │   │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌────────┐ ┌──────┐│   │
│  │  │ Home │ │Button│ │Clima │ │ Energy │ │Alarm ││   │
│  │  │ Page │ │Pages │ │ Page │ │  Page  │ │ Page ││   │
│  │  └──────┘ └──────┘ └──────┘ └────────┘ └──────┘│   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## Boot Sequence

Eiferer uses a **phased boot sequence** to ensure stability:

```
Phase 1 (priority 800) — Hardware Init
├── Initialize GPIO, UART, PSRAM
├── Check reset reason
├── If crash detected → enter Safe Mode
└── Log memory baseline

Phase 2 (priority 600) — Cache Restore
├── Load last-known page config from NVS
├── Restore display brightness
└── Render cached UI (panel is now USABLE)

Phase 3 (priority 200, +2s delay) — Blueprint Connect
├── Wait for API connection
├── Fire request_config event
└── Receive and apply fresh config from blueprint

Phase 4 (priority 100, +5s delay) — Add-on Init
├── Check available heap
├── Initialize enabled add-ons
└── Start periodic tasks (memory watchdog, NVS save)
```

The key insight: **Phase 2 makes the panel usable in ~2 seconds** using cached state, while Phases 3-4 happen in the background. The user sees their buttons and home page immediately.

---

## Memory Management

### The Problem

The ESP32 in the NSPanel has ~320KB of usable internal RAM and 8MB of PSRAM. After ESP-IDF, ESPHome, Wi-Fi, and Nextion stacks are loaded, only ~80-120KB of internal heap remains. The 2025 boot-loop crises happened when firmware exceeded this budget.

### Eiferer's Solution

**1. Memory Budget System**

Every component has a known memory cost. The diagnostics package exposes real-time sensors:

- `Free Heap` — current available internal RAM
- `Min Free Heap` — lowest point since boot (high-water mark)
- `Largest Free Block` — biggest contiguous allocation possible
- `Free PSRAM` — external RAM availability
- `Memory Health` — human-readable status (Healthy/OK/Low/Critical)

**2. Thresholds and Watchdog**

```
> 80KB free  →  Healthy (all features enabled)
> 30KB free  →  OK (normal operation, monitoring)
> 15KB free  →  Low (warning alert to HA, disable non-essential)
< 15KB free  →  Critical (emergency save and restart)
```

The memory watchdog runs every 30 seconds and will trigger a clean restart (with state saved) rather than allowing a hard crash.

**3. PSRAM Utilization**

Large buffers (Nextion command queue, display framebuffers) are allocated in PSRAM when available, keeping internal RAM free for the Wi-Fi stack and ESPHome core.

**4. Lazy Loading**

Add-ons don't initialize until 5 seconds after boot, and only if heap permits. If enabling the Bluetooth proxy would push memory below the warning threshold, it logs a warning instead of crashing.

---

## Event-Driven Communication

### The Problem

The original polling model required the ESPHome firmware to repeatedly request data from the blueprint, causing:

- Wi-Fi congestion during boot (multiple simultaneous requests)
- Slow responsiveness (waiting for next poll cycle)
- Wasted CPU cycles when nothing has changed

### Eiferer's Solution

All communication uses the Home Assistant Event Bus via `esphome.eiferer_event`:

**ESPHome → HA (panel events):**
```yaml
homeassistant.event:
  event: esphome.eiferer_event
  data:
    device_name: "living-room-panel"
    type: "button_press"          # Event type
    button: "left"                # Event-specific payload
```

**HA → ESPHome (service calls):**
```yaml
service: esphome.living_room_panel_notification_show
data:
  label: "Alert"
  text: "Motion detected"
  priority: "high"
```

Event types:

| Event Type | Direction | Description |
|---|---|---|
| `request_config` | ESP → HA | Panel requests full configuration |
| `button_press` | ESP → HA | Physical button pressed |
| `button_long_press` | ESP → HA | Physical button held >600ms |
| `page_change` | ESP → HA | Display page navigated |
| `gesture` | ESP → HA | Swipe gesture detected |
| `relay_change` | ESP → HA | Relay toggled |
| `climate_state` | ESP → HA | Climate mode/target changed |
| `climate_action` | ESP → HA | Heating/cooling started/stopped |
| `cover_action` | ESP → HA | Cover opening/closing/stopped |

---

## NVS State Caching

Non-Volatile Storage (NVS) on the ESP32 flash persists across reboots and power cycles. Eiferer caches:

- Current display page
- Display brightness
- Crash counter

This cache is saved every 5 minutes and before any OTA update or intentional restart. On boot, Phase 2 reads the cache and renders the UI immediately — before Wi-Fi even connects.

---

## Safe Mode

If the ESP32 detects a crash on the previous boot (via `esp_reset_reason()`), it enters Safe Mode:

- Core hardware initializes (relays, buttons, Wi-Fi)
- Add-ons are **not** loaded
- Display shows a "Safe Mode" status
- OTA updates still work (so you can fix the firmware wirelessly)
- The crash counter increments (visible in HA diagnostics)

This prevents the bricking scenario where a bad firmware causes infinite boot loops that can only be broken with USB.

---

## File Structure

```
nspanel-eiferer-blueprint/
├── eiferer_blueprint.yaml          # HA Blueprint (automation)
├── eiferer_esphome.yaml            # ESPHome entry point (includes sub-packages)
├── esphome/
│   ├── eiferer_core.yaml           # Hardware, boot, PSRAM, safe mode, Wi-Fi
│   ├── eiferer_standard.yaml       # Display, notifications, gestures, services
│   ├── eiferer_diagnostics.yaml    # Memory, Wi-Fi, uptime sensors
│   └── addons/
│       ├── eiferer_addon_upload_tft.yaml
│       ├── eiferer_addon_climate_heat.yaml
│       ├── eiferer_addon_climate_cool.yaml
│       ├── eiferer_addon_climate_dual.yaml
│       ├── eiferer_addon_cover.yaml
│       ├── eiferer_addon_display_light.yaml
│       ├── eiferer_addon_energy.yaml
│       └── eiferer_addon_bluetooth.yaml
├── docs/
│   ├── install.md
│   ├── configuration.md
│   ├── customization.md
│   ├── addons.md
│   ├── architecture.md             # (this file)
│   └── troubleshooting.md
├── scripts/
│   └── preflight.sh                # Pre-flash validation script
├── .github/workflows/
│   └── ci.yml                      # CI pipeline
├── CHANGELOG.md
├── LICENSE
└── README.md
```
