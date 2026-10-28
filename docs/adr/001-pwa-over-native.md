# ADR-001: Ship a PWA, not native apps

**Status:** Accepted (2026-10-23)

## Context
Simmer's first users are one household on iPhone, then family on mixed devices. Publishing
natively costs $99/yr (Apple) plus $25 (Google), and needs review cycles for every change.

## Decision
Build a Progressive Web App (React + TypeScript + Vite), served from S3 behind CloudFront and
installed with "Add to Home Screen".

## Consequences
- No store fees or review delays; every deploy is live immediately.
- iOS limits: web push works only for installed PWAs (iOS 16.4+), no background execution.
  Timers are stored as end timestamps so they survive the tab sleeping, and "timer done"
  notifications come from the server (EventBridge Scheduler → Web Push), not the device.
- Screen Wake Lock keeps the screen on during cook mode.
- If native ever becomes necessary, Capacitor can wrap the same codebase.
