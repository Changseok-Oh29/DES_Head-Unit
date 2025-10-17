# SEA-ME CommonAPI + vsomeip Implementation Plan

## 📁 Updated Project Structure

```
DES_Head-Unit/
├── app/
│   ├── HU_app/                 # Head Unit Qt Application
│   └── IC_app/                 # Instrument Cluster Qt Application
├── commonapi/                  # 🆕 CommonAPI Interface Definitions
│   ├── fidl/                   # FIDL Interface Files
│   │   ├── VehicleControl.fidl # ECU1 - Vehicle Control Service
│   │   ├── MediaControl.fidl   # HU - Media Control Service
│   │   └── AmbientLight.fidl   # HU - Ambient Lighting Service
│   ├── generated/              # Auto-generated Stub/Proxy Code
│   └── CMakeLists.txt          # CommonAPI Build Configuration
├── services/                   # 🆕 Service Implementations
│   ├── vehicle_service/        # ECU1 Mock Service
│   ├── media_service/          # Media Control Service
│   ├── ambient_service/        # Ambient Light Service
│   └── ic_service/             # IC Data Display Service
├── meta/                       # Yocto Build System
└── .github/workflows/          # CI/CD Pipeline
```

## 🎯 Implementation Phases

### Phase 1: Environment Setup (1-2 days)
- [x] CommonAPI FIDL interfaces created
- [ ] Install CommonAPI Core & SomeIP libraries
- [ ] Install Code Generator tools
- [ ] Configure vsomeip library
- [ ] Update CMake build system

### Phase 2: Code Generation (1 day)
- [ ] Generate Stub/Proxy classes from FIDL
- [ ] Create service implementation skeletons
- [ ] Configure vsomeip.json service discovery

### Phase 3: Mock Service Implementation (3-4 days)
- [ ] VehicleControlService: Gear/Battery/Speed simulation
- [ ] MediaControlService: USB media scanning & playback
- [ ] AmbientLightService: Color calculation logic
- [ ] IC Service: Data reception and display

### Phase 4: Integration Testing (2-3 days)
- [ ] RPC communication tests
- [ ] Event subscription tests  
- [ ] End-to-end scenario tests
- [ ] Performance and reliability tests

### Phase 5: Qt Application Integration (3-4 days)
- [ ] Replace IpcManager with CommonAPI Proxy
- [ ] Replace DBusReceiver with CommonAPI Proxy
- [ ] Update QML data bindings
- [ ] Yocto meta-layer integration

## 🔧 Next Immediate Steps

1. **Install CommonAPI Environment**
   ```bash
   # Install CommonAPI Core and SomeIP generator
   sudo apt-get install commonapi-core-dev commonapi-someip-dev
   ```

2. **Generate Stub/Proxy Code**
   ```bash
   # Generate from FIDL files
   commonapi-core-generator -sk fidl/VehicleControl.fidl
   commonapi-someip-generator fidl/VehicleControl.fidl
   ```

3. **Create Mock VehicleControl Service**
   - Implement gear state management
   - Generate fake battery/speed data
   - Handle RPC requests and broadcast events

4. **Test Communication**
   - Start VehicleControl service
   - Connect HU client proxy
   - Verify gear change: HU → ECU1 → IC

## 💡 Key Design Decisions

### Communication Patterns
- **RPC**: Gear changes, media control commands
- **Events**: Status updates (battery, speed, volume)
- **Internal**: UDS for same-ECU communication  
- **External**: TCP/UDP for ECU-to-ECU communication

### Service Architecture
```
┌─────────────┐    vsomeip    ┌─────────────┐
│ HU Services │◄─────────────►│ ECU1 Service│
│ - Media     │               │ - Vehicle   │
│ - Ambient   │               │ - Battery   │
└─────────────┘               └─────────────┘
       │                             │
       │ UDS (internal)              │ vsomeip
       ▼                             ▼
┌─────────────┐               ┌─────────────┐
│  HU_app     │               │   IC_app    │
│ (Qt/QML UI) │               │ (Qt/QML UI) │
└─────────────┘               └─────────────┘
```

### Benefits of This Approach
✅ **AUTOSAR Compliance**: Industry standard architecture
✅ **Modularity**: Services can be developed/tested independently  
✅ **Scalability**: Easy to add new services/features
✅ **Maintainability**: Auto-generated code reduces bugs
✅ **Team Collaboration**: Clear interface contracts

## 🚀 Ready to Start?

The foundation is now set up. We can immediately begin with:
1. CommonAPI environment installation
2. Code generation from existing FIDL files
3. Mock service implementation
4. Communication testing

Which phase would you like to tackle first?
