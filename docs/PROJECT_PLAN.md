# PMBOK Project Management Plan

This document outlines the project management approach following PMBOK (Project Management Body of Knowledge) best practices.

## Project Overview

| Attribute | Value |
|-----------|-------|
| Project Name | GlobPretect |
| Description | VPN connection manager for HPCC RedRaider |
| Repository | github.com/sweeden-ttu/GlobPretect |
| Owner | sweeden-ttu |

## Project Phases (PMBOK)

### 1. Initiating Phase
- [x] Define project charter
- [x] Identify stakeholders
- [x] Define initial scope

### 2. Planning Phase
- [ ] Create WBS
- [ ] Define schedule milestones
- [ ] Plan budget/resources
- [ ] Identify risks
- [ ] Define quality standards

### 3. Executing Phase
- [ ] Execute WBS tasks
- [ ] Manage stakeholder engagement
- [ ] Implement quality assurance

### 4. Monitoring & Controlling Phase
- [ ] Monitor scope, schedule, cost
- [ ] Perform quality control
- [ ] Monitor risk responses
- [ ] Report performance

### 5. Closing Phase
- [ ] Release resources
- [ ] Document lessons learned
- [ ] Archive project documents

## Milestones

### Phase 1: Foundation (Week 1-2)
| Milestone | Target | Status |
|-----------|--------|--------|
| Project charter approved | Week 1 | ✅ Complete |
| Repository created | Week 1 | ✅ Complete |
| SSH tunnel scripts | Week 2 | ✅ Complete |

### Phase 2: Core Development (Week 3-6)
| Milestone | Target | Status |
|-----------|--------|--------|
| Basic VPN connection | Week 3 | 🔄 In Progress |
| SSH tunnel automation | Week 4 | ⏳ Pending |
| Port forwarding management | Week 5 | ⏳ Pending |
| Ollama integration | Week 6 | ⏳ Pending |

### Phase 3: Enhancement (Week 7-10)
| Milestone | Target | Status |
|-----------|--------|--------|
| Auto-reconnect logic | Week 7 | ⏳ Pending |
| Connection status UI | Week 8 | ⏳ Pending |
| HPCC job tunnel support | Week 9 | ⏳ Pending |
| Security hardening | Week 10 | ⏳ Pending |

### Phase 4: Polish & Release (Week 11-12)
| Milestone | Target | Status |
|-----------|--------|--------|
| Beta testing | Week 11 | ⏳ Pending |
| Release v1.0 | Week 12 | ⏳ Pending |

## Work Breakdown Structure (WBS)

```
GlobPretect
├── 1. Project Management
│   ├── 1.1 Project Charter
│   ├── 1.2 Planning
│   └── 1.3 Closing
├── 2. VPN Core
│   ├── 2.1 Connection Manager
│   ├── 2.2 Authentication
│   └── 2.3 Auto-reconnect
├── 3. SSH Tunnels
│   ├── 3.1 Tunnel Creation
│   ├── 3.2 Port Forwarding
│   └── 3.3 Tunnel Monitoring
├── 4. Ollama Integration
│   ├── 4.1 Port 55077 (granite4)
│   └── 4.2 Port 66044 (qwen-coder)
├── 5. HPCC Integration
│   ├── 5.1 Job Detection
│   ├── 5.2 Dynamic Tunnels
│   └── 5.3 GPU Node Access
└── 6. Testing & Deployment
    ├── 6.1 Unit Tests
    └── 6.2 Release Package
```

## Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R1 | HPCC network changes | Medium | High | Dynamic tunnel recreation |
| R2 | SSH key expiration | Low | High | Key rotation automation |
| R3 | Port conflicts | Medium | Medium | Port validation before binding |
| R4 | VPN disconnection during job | Medium | High | Auto-reconnect logic |

## Success Criteria

1. Reliable VPN connection to HPCC
2. Automatic SSH tunnel management
3. Seamless Ollama port forwarding (55077, 66044)
4. Daily GitHub sync operational
5. Integration with data-structures library

## Dependencies

- **data-structures**: Queue, PriorityQueue for connection management
- **OllamaHpcc**: Ollama service integration

## Lessons Learned

*(To be updated throughout the project)*
