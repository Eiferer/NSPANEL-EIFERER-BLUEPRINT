# Changelog

All notable changes to the NSPanel Eiferer Blueprint will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to integer-based versioning: `YYYYMMx` (e.g. `2026021` = February 2026, release 1).

---

## [2026021] - 2026-02-26

### Added
- Initial release of NSPanel Eiferer Blueprint
- Memory budget system with real-time heap monitoring and low-memory alerts
- Safe-mode fallback with crash detection (no more USB recovery)
- NVS state caching for instant boot UI (<2 seconds to usable display)
- Event-driven blueprint ↔ ESPHome communication architecture
- Lazy-loaded add-on system — components initialize only when enabled
- PSRAM-aware buffer allocation for Nextion command queues
- CRC-verified atomic TFT update system
- Version compatibility pre-flight checks (blueprint ↔ ESPHome ↔ TFT)
- Notification priority queue with buzzer support (high / normal / low)
- Swipe gesture support on home page (configurable actions)
- Energy dashboard add-on page
- Multi-panel coordination for linked NSPanels
- Presence-aware display modes (always_on / auto / glance / touch_only)
- Scene preview before activation
- Structured logging with per-subsystem tags
- CI pipeline: firmware size checks, blueprint validation, compatibility matrix
- Full documentation suite

### Changed
- Architecture rebuilt from polling to event-driven model
- Boot sequence redesigned with phased initialization
- Add-ons are now fully lazy-loaded instead of compiled-in
- TFT transfer uses checksums and rollback protection

### Fixed
- Memory exhaustion boot loops (root cause: no memory budgeting)
- Blank screen on reboot while waiting for blueprint data
- Wi-Fi overload during boot from excessive API requests
- Panel crashes when disconnected from Home Assistant
