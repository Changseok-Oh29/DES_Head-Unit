# Multi-Process vSOMEIP Testing Guide

This guide shows how to run MediaApp and AmbientApp as **separate processes** and test vSOMEIP communication between them.

## 🎯 Architecture

```
MediaApp (Process 1)              AmbientApp (Process 2)
     │                                    │
     │ [Service Provider]                 │ [Client/Subscriber]
     │ Service ID: 0x1235                 │ Service ID: 0x1235
     │ Instance: 0x5679                   │ Instance: 0x5679
     │ App ID: 0x1234                     │ App ID: 0x1236
     │                                    │
     │ Offers: volumeChanged event        │ Subscribes to: volumeChanged
     │          getVolume() method        │
     │                                    │
     └─────────[vSOMEIP/UDP]──────────────┘
              Port 30509
         Service Discovery: 224.0.0.1:30490
```

## 📋 Prerequisites

1. ✅ **Built executables:**
   ```bash
   cmake -B build -DBUILD_MEDIA_APP=ON -DBUILD_AMBIENT_APP=ON
   cmake --build build -j4
   ```

2. ✅ **vsomeip configuration files:**
   - `/app/MediaApp/vsomeip.json` - Service provider config
   - `/app/AmbientApp/vsomeip.json` - Client config

3. ✅ **CommonAPI configuration files:**
   - `/app/MediaApp/commonapi.ini`
   - `/app/AmbientApp/commonapi.ini`

## 🚀 How to Run (Simple Method)

### **Terminal 1: Launch MediaApp (Service)**

```bash
cd /home/seam/DES_Head-Unit
./run_mediaapp.sh
```

**Wait for:**
```
✅ MediaControl vsomeip service registered successfully
OFFER(1234): [1235.5679:1.0]
```

### **Terminal 2: Launch AmbientApp (Client)**

```bash
cd /home/seam/DES_Head-Unit
./run_ambientapp.sh
```

**Wait for:**
```
[AmbientApp] MediaControlClient: Service is now AVAILABLE!
[AmbientApp] MediaControlClient: Successfully subscribed to events
```

## 🧪 Testing the Communication

### **Test 1: Initial Sync (RPC)**

When AmbientApp starts, it should automatically request the current volume:

**Expected logs:**
```
[AmbientApp] MediaControlClient: Requesting current volume...
[MediaApp] MediaControlStubImpl: getVolume() called, returning: 0.8
[AmbientApp] MediaControlClient: Current volume: 0.8
[AmbientApp] MediaControlClient: Setting brightness to: 0.9
AmbientManager: Brightness changed: 1 -> 0.9
```

✅ **Success:** AmbientApp received initial volume via RPC

---

### **Test 2: Real-Time Events (Broadcast)**

1. **In MediaApp window:**
   - Click on the volume slider
   - Drag it to change volume

2. **Watch both terminals:**

**MediaApp logs:**
```
[MediaApp] MediaControlStubImpl: Volume changed to: 0.6
[MediaApp] MediaControlStubImpl: volumeChanged event broadcasted
```

**AmbientApp logs:**
```
[AmbientApp] MediaControlClient: Received volumeChanged event: 0.6
[AmbientApp] MediaControlClient: Setting brightness to: 0.8 (from volume: 0.6)
AmbientManager: Brightness changed: 0.9 -> 0.8
```

✅ **Success:** AmbientApp received broadcast event in real-time!

---

## 🔍 Troubleshooting

### ❌ Problem: "Service became UNAVAILABLE"

**Symptoms:**
```
[AmbientApp] MediaControlClient: Service became UNAVAILABLE!
```

**Solutions:**

1. **Check MediaApp is running first:**
   ```bash
   ps aux | grep MediaApp
   ```

2. **Check vsomeip routing:**
   - MediaApp must be running BEFORE AmbientApp
   - MediaApp acts as routing manager (see `"routing": "MediaApp_Service"` in vsomeip.json)

3. **Check multicast routing (if needed):**
   ```bash
   # Add multicast route for service discovery
   sudo route add -net 224.0.0.0 netmask 240.0.0.0 dev lo

   # Verify
   route -n | grep 224.0.0.0
   ```

4. **Enable debug logging:**

   Edit both vsomeip.json files:
   ```json
   "logging": {
       "level": "debug",
       "console": "true"
   }
   ```

---

### ❌ Problem: No events received

**Check:**

1. **Service is offered:**
   ```bash
   # In MediaApp logs, look for:
   OFFER(1234): [1235.5679:1.0]
   ```

2. **Client subscribed:**
   ```bash
   # In AmbientApp logs, look for:
   SUBSCRIBE(1236): [1235.5679.1235:9ca4:1]
   SUBSCRIBE ACK(1234): [1235.5679.1235.9ca4]
   ```

3. **Volume actually changed:**
   - Make sure you moved the slider in MediaApp UI
   - Check if MediaManager emits the signal

---

### ❌ Problem: "Failed to create proxy"

**Solution:**
```bash
# Make sure LD_LIBRARY_PATH includes CommonAPI libraries
export LD_LIBRARY_PATH=/home/seam/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH

# Make sure VSOMEIP_CONFIGURATION is set
export VSOMEIP_CONFIGURATION=/home/seam/DES_Head-Unit/app/AmbientApp/vsomeip.json
```

---

## 📊 Expected Communication Flow

### Startup Sequence:

```
1. MediaApp starts
   → Registers service 0x1235.0x5679
   → Offers volumeChanged event
   → Becomes routing manager
   → Status: READY

2. AmbientApp starts
   → Connects to MediaApp's routing
   → Discovers service 0x1235.0x5679
   → Creates proxy
   → Status: WAITING FOR SERVICE

3. Service Discovery completes
   → AmbientApp: "Service is now AVAILABLE!"
   → Subscribes to volumeChanged event
   → Calls getVolume() to sync initial state
   → Status: FULLY CONNECTED

4. User changes volume in MediaApp
   → MediaManager emits volumeChanged()
   → MediaControlStubImpl fires event
   → vSOMEIP broadcasts to all subscribers
   → AmbientApp receives event
   → Updates brightness
   → Status: COMMUNICATION ACTIVE ✅
```

---

## 🎮 Manual Testing Checklist

- [ ] MediaApp starts without errors
- [ ] MediaApp shows "service registered successfully"
- [ ] AmbientApp starts without errors
- [ ] AmbientApp shows "Service is now AVAILABLE!"
- [ ] AmbientApp subscribes to events successfully
- [ ] Initial volume sync works (getVolume RPC)
- [ ] Initial brightness is set correctly
- [ ] Moving MediaApp volume slider triggers events
- [ ] AmbientApp receives volumeChanged events
- [ ] Brightness updates in real-time
- [ ] Volume 0.0 → Brightness 0.5
- [ ] Volume 0.5 → Brightness 0.75
- [ ] Volume 1.0 → Brightness 1.0

---

## 🔧 Advanced: Using tmux for Side-by-Side View

```bash
# Start tmux session
tmux new -s vsomeip_test

# Split window vertically
# Ctrl+B then %

# Left pane: MediaApp
./run_mediaapp.sh

# Switch to right pane: Ctrl+B then →
# Right pane: AmbientApp
./run_ambientapp.sh

# Navigate between panes: Ctrl+B then arrow keys
# Exit tmux: Ctrl+B then D
```

---

## 📌 Key Configuration Values

| Parameter | MediaApp | AmbientApp |
|-----------|----------|------------|
| App Name | `MediaApp_Service` | `AmbientApp_Client` |
| App ID | `0x1234` (4660) | `0x1236` (4662) |
| Service ID | `0x1235` (4661) | `0x1235` (4661) |
| Instance ID | `0x5679` (22137) | `0x5679` (22137) |
| Role | Service Provider | Client/Subscriber |
| Routing | Acts as routing manager | Connects to MediaApp routing |
| Port | 30509 (UDP) | - |

---

## ✅ Success Criteria

Your multi-process vSOMEIP communication is working if:

1. ✅ MediaApp offers service successfully
2. ✅ AmbientApp discovers service automatically
3. ✅ Initial RPC (getVolume) returns correct value
4. ✅ Event subscription succeeds (SUBSCRIBE ACK received)
5. ✅ Volume changes trigger real-time broadcast events
6. ✅ AmbientApp receives events and updates brightness
7. ✅ Brightness formula correct: `brightness = 0.5 + (volume × 0.5)`

---

## 🎓 What You're Testing

This setup demonstrates **automotive-grade inter-process communication**:

- **Service Discovery:** Automatic service location via multicast
- **RPC (Request/Response):** `getVolume()` method call
- **Event/Notification:** `volumeChanged` broadcast to all subscribers
- **Decoupling:** MediaApp doesn't know AmbientApp exists
- **Real-time:** Zero-latency event delivery
- **Scalability:** Multiple clients can subscribe to same event

This is the **exact pattern** used in production automotive systems! 🚗
