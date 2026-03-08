import { useState } from "react";

const checks = [
  {
    category: "Windows Audio Stack",
    color: "#00d4ff",
    items: [
      {
        id: "w1",
        label: "Set Focusrite as Default Device",
        detail: 'Right-click speaker icon → Sound Settings → set Scarlett as both "Output" and "Default"',
      },
      {
        id: "w2",
        label: "Set Focusrite as Default Communications Device",
        detail: "Same Sound Settings panel — set it for Communications too, not just playback",
      },
      {
        id: "w3",
        label: "Disable Exclusive Mode",
        detail: "Sound → Focusrite Properties → Advanced → uncheck both 'Allow exclusive mode' boxes",
      },
      {
        id: "w4",
        label: "Disable Audio Enhancements",
        detail: "Same Properties panel → Enhancements tab → check 'Disable all enhancements'",
      },
      {
        id: "w5",
        label: "Set sample rate to 48000 Hz / 24-bit",
        detail: "Properties → Advanced → Format dropdown → match this to your Resolve project settings",
      },
      {
        id: "w6",
        label: "Check Windows Audio service is running",
        detail: "Run: services.msc → Windows Audio → should be Running + Automatic",
      },
    ],
  },
  {
    category: "USB & Hardware",
    color: "#ff6b35",
    items: [
      {
        id: "u1",
        label: "Focusrite direct to motherboard USB port",
        detail: "No hubs, docks, or extensions — confirmed direct ✓",
      },
      {
        id: "u2",
        label: "Use a USB 3.0 port (blue) not USB-C adapter",
        detail: "Scarlett performs most reliably on a dedicated USB-A 3.0 port",
      },
      {
        id: "u3",
        label: "Check Focusrite is on its own USB controller",
        detail: "Device Manager → Universal Serial Bus controllers → expand each host controller, Scarlett should be alone",
      },
      {
        id: "u4",
        label: "Disable USB Selective Suspend for audio port",
        detail: "Power Options → Change plan settings → Advanced → USB settings → Selective Suspend → Disabled",
      },
      {
        id: "u5",
        label: "Check DisplayLink is NOT on same USB controller",
        detail: "Your logs show DisplayLink as a GPU — it causes bandwidth contention with audio if sharing a controller",
      },
    ],
  },
  {
    category: "Focusrite Scarlett Software",
    color: "#a8ff3e",
    items: [
      {
        id: "f1",
        label: "Focusrite Control app: check sample rate lock",
        detail: "Open Focusrite Control → ensure sample rate matches your Resolve project (48kHz typical)",
      },
      {
        id: "f2",
        label: "Check firmware is up to date",
        detail: "Focusrite Control → About → check for firmware updates",
      },
      {
        id: "f3",
        label: "Set buffer size in Focusrite Control",
        detail: "For Resolve editing (not live monitoring): set to 256 or 512 samples for stability",
      },
      {
        id: "f4",
        label: "Disable Direct Monitor if not needed",
        detail: "Direct Monitor knob on hardware — set to off unless you need zero-latency monitoring",
      },
    ],
  },
  {
    category: "DaVinci Resolve Audio Settings",
    color: "#ff3eb5",
    items: [
      {
        id: "r1",
        label: "Preferences → Audio I/O → set to Focusrite explicitly",
        detail: "DaVinci Resolve → Preferences → System → Audio I/O → select Scarlett, not 'Default'",
      },
      {
        id: "r2",
        label: "Match Resolve project sample rate to Scarlett",
        detail: "Project Settings → Master Settings → Timeline audio sample rate → 48000 Hz",
      },
      {
        id: "r3",
        label: "Check audio output bus in Fairlight",
        detail: "Fairlight page → Bus Format panel → ensure Main Out is routed to Focusrite channels 1/2",
      },
      {
        id: "r4",
        label: "Disable 'Use Audio Scratch Disk' if on HDD",
        detail: "Preferences → Media Storage → audio scratch should be on your fastest NVMe, not HDD",
      },
      {
        id: "r5",
        label: "GPU memory mode — set to CUDA/ROCm not Auto",
        detail: "Preferences → Memory and GPU → GPU selection → force AMD RX 6900 XT, not Auto",
      },
    ],
  },
  {
    category: "Background Processes",
    color: "#ffd700",
    items: [
      {
        id: "p1",
        label: "Kill LogiOptionsPlus before Resolve sessions",
        detail: "Your logs show it delays system shutdown 5x — it can interfere with audio device enumeration",
      },
      {
        id: "p2",
        label: "Disable WLAN AutoConfig if on wired ethernet",
        detail: "Logs show Intel WiFi module crashing 5x — if you're wired, disable WiFi entirely in Device Manager",
      },
      {
        id: "p3",
        label: "Check GameInputSvc interference",
        detail: "Logs show GameInputSvc blocking HID device ejection — disable via services.msc if no controller needed",
      },
      {
        id: "p4",
        label: "Verify no other app has exclusive audio lock",
        detail: "Close Discord, browsers, Spotify before Resolve — any app with exclusive mode will block Focusrite",
      },
    ],
  },
];

export default function AudioChecklist() {
  const [checked, setChecked] = useState({});
  const [expanded, setExpanded] = useState({});

  const toggle = (id) => setChecked((p) => ({ ...p, [id]: !p[id] }));
  const toggleExpand = (id) => setExpanded((p) => ({ ...p, [id]: !p[id] }));

  const total = checks.flatMap((c) => c.items).length;
  const done = Object.values(checked).filter(Boolean).length;
  const pct = Math.round((done / total) * 100);

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0a0a0f",
      fontFamily: "'Courier New', monospace",
      padding: "32px 24px",
      color: "#e0e0e0",
    }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>

        {/* Header */}
        <div style={{ marginBottom: 32 }}>
          <div style={{ fontSize: 11, letterSpacing: 4, color: "#555", marginBottom: 8, textTransform: "uppercase" }}>
            DaVinci Resolve · Focusrite Scarlett · Win11
          </div>
          <h1 style={{
            fontSize: 26,
            fontWeight: 700,
            margin: "0 0 4px",
            color: "#fff",
            letterSpacing: -0.5,
          }}>
            Audio Diagnostic Checklist
          </h1>
          <div style={{ fontSize: 12, color: "#555" }}>Based on your event log · {new Date().toLocaleDateString("en-GB")}</div>
        </div>

        {/* Progress */}
        <div style={{ marginBottom: 36 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, fontSize: 12, color: "#888" }}>
            <span>{done} / {total} checks completed</span>
            <span style={{ color: pct === 100 ? "#a8ff3e" : "#00d4ff" }}>{pct}%</span>
          </div>
          <div style={{ height: 3, background: "#1a1a2e", borderRadius: 2 }}>
            <div style={{
              height: "100%",
              width: `${pct}%`,
              background: pct === 100 ? "#a8ff3e" : "linear-gradient(90deg, #00d4ff, #a8ff3e)",
              borderRadius: 2,
              transition: "width 0.4s ease",
            }} />
          </div>
        </div>

        {/* Categories */}
        {checks.map((cat) => {
          const catDone = cat.items.filter((i) => checked[i.id]).length;
          return (
            <div key={cat.category} style={{ marginBottom: 28 }}>
              <div style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                marginBottom: 12,
              }}>
                <div style={{ width: 3, height: 18, background: cat.color, borderRadius: 2, flexShrink: 0 }} />
                <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", color: cat.color }}>
                  {cat.category}
                </span>
                <span style={{ fontSize: 10, color: "#444", marginLeft: "auto" }}>
                  {catDone}/{cat.items.length}
                </span>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {cat.items.map((item) => (
                  <div key={item.id} style={{
                    background: checked[item.id] ? "rgba(168,255,62,0.04)" : "#0f0f1a",
                    border: `1px solid ${checked[item.id] ? "rgba(168,255,62,0.2)" : "#1c1c2e"}`,
                    borderRadius: 6,
                    overflow: "hidden",
                    transition: "all 0.2s ease",
                  }}>
                    <div style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 12,
                      padding: "11px 14px",
                      cursor: "pointer",
                    }} onClick={() => toggle(item.id)}>
                      {/* Checkbox */}
                      <div style={{
                        width: 18,
                        height: 18,
                        border: `1.5px solid ${checked[item.id] ? "#a8ff3e" : "#333"}`,
                        borderRadius: 3,
                        background: checked[item.id] ? "#a8ff3e" : "transparent",
                        flexShrink: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        transition: "all 0.15s ease",
                      }}>
                        {checked[item.id] && (
                          <svg width="10" height="8" viewBox="0 0 10 8" fill="none">
                            <path d="M1 4l3 3 5-6" stroke="#0a0a0f" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                        )}
                      </div>

                      <span style={{
                        fontSize: 13,
                        color: checked[item.id] ? "#666" : "#ccc",
                        textDecoration: checked[item.id] ? "line-through" : "none",
                        flex: 1,
                        transition: "all 0.2s",
                      }}>
                        {item.label}
                      </span>

                      {/* Expand toggle */}
                      <div
                        onClick={(e) => { e.stopPropagation(); toggleExpand(item.id); }}
                        style={{
                          color: "#444",
                          fontSize: 10,
                          cursor: "pointer",
                          padding: "2px 6px",
                          borderRadius: 3,
                          border: "1px solid #222",
                          letterSpacing: 1,
                          userSelect: "none",
                          flexShrink: 0,
                        }}
                      >
                        {expanded[item.id] ? "▲" : "▼"}
                      </div>
                    </div>

                    {expanded[item.id] && (
                      <div style={{
                        padding: "0 14px 12px 44px",
                        fontSize: 11,
                        color: "#666",
                        lineHeight: 1.7,
                        borderTop: "1px solid #161625",
                        paddingTop: 10,
                      }}>
                        {item.detail}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          );
        })}

        {/* Footer */}
        {pct === 100 && (
          <div style={{
            marginTop: 24,
            padding: "16px 20px",
            background: "rgba(168,255,62,0.06)",
            border: "1px solid rgba(168,255,62,0.3)",
            borderRadius: 8,
            textAlign: "center",
            fontSize: 13,
            color: "#a8ff3e",
            letterSpacing: 2,
            textTransform: "uppercase",
          }}>
            ✓ All checks complete — retest Resolve
          </div>
        )}

        <div style={{ marginTop: 32, fontSize: 10, color: "#2a2a3e", textAlign: "center", letterSpacing: 2 }}>
          GENERATED FROM WINDOWS EVENT LOG · {total} DIAGNOSTIC CHECKS
        </div>
      </div>
    </div>
  );
}
