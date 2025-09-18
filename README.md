# Nokia TWAMP Test Lab with Containerlab

This is a Nokia lab demonstrating TWAMP (Two-Way Active Measurement Protocol) testing between network devices using Nokia SR OS simulators. The lab includes a complete network topology with TWAMP originator and reflector endpoints for performance measurement testing.

![Network Topology](./topology/topologyv4.png)

## Overview

The lab implements a TWAMP test scenario where:
- **NID (Originator)**: Nokia IXR-e2c device that initiates TWAMP tests
- **Reflector**: Peering Router (7750 SR-1) reflects TWAMP packets back to the originator
- **Network Path**: Complete L2/L3 network infrastructure between originator and CPE. NID runs a local L2 service with no MPLS.

The TWAMP session measures round-trip delay and packet loss between the originator (172.20.20.109) and reflector (172.20.20.107) endpoints through a realistic network topology including aggregation, service provider edge, and core networking elements.

## Lab Components

### Network Devices
- **ce**: Customer Edge (Nokia IXR-e2c)
- **nid**: Network demarcation device (Nokia IXR-e2c) - TWAMP originator
- **cpe**: Customer Premises Equipment (Nokia IXR-e2c)
- **agg**: Aggregation Router (Nokia IXR-e2)
- **spe**: Service Provider Edge (Nokia SR-1)
- **coi-l2**: Core of Internet L2 (Nokia SR-1)
- **coi-l3**: Core of Internet L3 (Nokia SR-1)
- **peering**: Peering Router (Nokia SR-1) - TWAMP reflector

### Test Endpoints
- **tester1**: Linux host (172.16.0.2) connected to CE
- **tester2**: Linux host (192.168.200.2) connected to peering router

## Getting Started

### Prerequisites
- Containerlab installed
- Nokia SROS license file available
- Docker with Nokia SR OS simulator images

### Deployment

1. **Deploy the topology:**
   ```bash
   sudo containerlab deploy -t topo.clab.yml
   ```

2. **Verify deployment:**
   ```bash
   sudo containerlab inspect -t topo.clab.yml
   ```

**Note:** Make sure you have updated/uploaded the Nokia SROS License File in the location specified in the license section of the topology file (`../license-srsim25.txt`).

## TWAMP Configuration

### TWAMP Session Details
- **Session Name**: `toPeering`
- **Test Direction**: NID (172.20.20.109) → Peering router (172.20.20.107)
- **Source Address**: `2001::a:1` (NID Originator)
- **Destination Address**: `2001::f:0` (Peering Reflector)
- **UDP Port**: 64364
- **Test ID**: 100708
- **Interval**: 1 seconds (1000ms)
- **Pad Size**: 5 bytes
- **Measurement Interval**: 5 minutes
- **Statistics**: log to accounting file but also available via Streaming Telemetry

### Key Configuration Elements

#### Originator Configuration
- TWAMP-Light reflector enabled on originator device
- OAM-PM session configured with delay measurement template
- IPv6 addressing for TWAMP endpoints

#### CPE Reflector Configuration  
- TWAMP-Light reflector service configured
- Accepts TWAMP tests from originator prefix range
- VPRN service for TWAMP traffic isolation with static route and rVPLS to L2 service

## Performance Monitoring

### Collecting TWAMP Statistics

To retrieve the average round-trip delay from the TWAMP test session, use the provided script:

```bash
./gnmic_twamp.sh
```

This script uses gNMI to subscribe to TWAMP statistics and extracts the average delay measurement from the originator device.

**Manual gNMI Command:**

First, we get the latest interval-number
```bash
$ gnmic -a 172.20.20.1079 -u grpc -p telemetry --insecure get --format flat --path "/state/oam-pm/session[session-name=toCPE]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/newest-index"

state/oam-pm/session[session-name=toCPE]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/newest-index: 14

$completed=13
```

For Streaming Telemetry, we choose the previous interval-number that was completed.
```bash
gnmic -a 172.20.20.109 -u grpc -p telemetry --insecure subscribe --format flat --path "/state/oam-pm/session[session-name=toPeering]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/number[mi-number=$completed]/bin-type[bin-metric=fd]/round-trip/average"

state/oam-pm/session[session-name=toPeering]/ip/twamp-light/statistics/delay/measurement-interval[duration=5-mins]/number[mi-number=13]/bin-type[bin-metric=fd]/round-trip/average: 9735
```

### Available Metrics
- Round-trip delay (average, minimum, maximum)
- Forward and backward delay measurements
- Packet loss statistics
- Jitter measurements
- Streaming telemetry data

## Network Architecture

The lab implements a realistic service provider network with:
- **Access Layer**: CE and CPE devices
- **Aggregation Layer**: AGG router with MPLS connectivity
- **Core Layer**: SPE and COI routers providing L2/L3 services
- **Peering Layer**: External connectivity simulation

### Protocol Stack
- **L2**: Ethernet, VLAN (802.1Q)
- **L3**: IPv4/IPv6, ISIS, MPLS
- **Services**: VPRN, EPIPE
- **OAM**: TWAMP-Light for performance measurement

## File Structure

```
twamp_coi/
├── topo.clab.yml              # Main topology definition
├── topology.png               # Network diagram
├── gnmic_twamp.sh             # TWAMP statistics collection script
├── save_config.sh             # Configuration backup script
├── startup_config/            # Device startup configurations
│   ├── peering.partial.txt    # TWAMP reflector config
│   ├── nid.partial.txt        # TWAMP originator config
│   └── *.partial.txt          # Other device 
```

## Troubleshooting

### Common Issues

1. **License File Missing**: Ensure Nokia SROS license is available at the specified path
2. **Port Conflicts**: Check if management ports (172.20.20.x) are available
3. **TWAMP Session Down**: Verify IPv6 connectivity between originator and CPE
4. **gNMI Connection Issues**: Confirm grpc user credentials and device accessibility

### Verification Commands

**Check TWAMP session status on originator:**
Make sure to choose the latest completed interval, in this example interval-number is 2 and the latest in-progress is always 1.
```bash
ssh admin@nid

A:admin@nid# /show oam-pm statistics session "toPeering" twamp-light meas-interval 5-mins interval-number 2

------------------------------------------------------------------------------
Start (UTC)       : 2025/09/18 16:30:00          Status          : completed
Elapsed (seconds) : 300                          Suspect         : no
Frames Sent       : 300                          Frames Received : 300
------------------------------------------------------------------------------
===============================================================================
TWAMP-LIGHT DELAY STATISTICS

----------------------------------------------------------------------------
Bin Type     Direction     Minimum (us)   Maximum (us)   Average (us)   EfA
----------------------------------------------------------------------------
FD           Forward               4302           8267           5583    no
FD           Backward              3908           6768           5217    no
FD           Round Trip            8731          13356          10801    no
FDR          Forward                  0           3965           1273    no
FDR          Backward                 0           2830           1289    no
FDR          Round Trip             224           4849           2294    no
IFDV         Forward                  2           2453            532    no
IFDV         Backward                 3           1470            479    no
IFDV         Round Trip               3           3045            830    no
----------------------------------------------------------------------------

EfA = yes: one or more bins configured to be Excluded from the Average calc.

---------------------------------------------------------------
Frame Delay (FD) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us             0             0             0
1            2000 us             0             1             0
2            4000 us           256           283             0
3            6000 us            43            16             0
4            8000 us             1             0            40
5           10000 us             0             0           260
---------------------------------------------------------------

---------------------------------------------------------------
Frame Delay Range (FDR) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us           279           280           102
1            2000 us            21            20           190
2            4000 us             0             0             8
3            6000 us             0             0             0
4            8000 us             0             0             0
5           10000 us             0             0             0
---------------------------------------------------------------

---------------------------------------------------------------
Inter-Frame Delay Variation (IFDV) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us           297           300           287
1            2000 us             3             0            13
2            4000 us             0             0             0
3            6000 us             0             0             0
4            8000 us             0             0             0
5           10000 us             0             0             0
---------------------------------------------------------------
===============================================================================
===============================================================================
TWAMP-LIGHT LOSS STATISTICS: NONE
===============================================================================
```

**Verify TWAMP reflector on Peering router:**
```bash
ssh admin@peering

A:admin@peering# /show router twamp-light 

-------------------------------------------------------------------------------
TWAMP-Light Reflector
-------------------------------------------------------------------------------
Admin State          : Up                      UDP Port         : 64364
IPv6 UDP Checksum 0  : Disallow                
Description          : (Not Specified)
Up Time              : 0d 19:40:09             
Test Frames Received : 70716                   Test Frames Sent : 70716
Type                 : TWAMP-Light             
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
TWAMP-Light Reflector Prefixes
-------------------------------------------------------------------------------
Prefix                                      Description
-------------------------------------------------------------------------------
2001::a:0/127                               
-------------------------------------------------------------------------------
No. of TWAMP-Light Reflector Prefixes: 1
-------------------------------------------------------------------------------
```

**Test network connectivity:**
IPv6 ping between originator and reflector
```bash
ssh admin@peering

A:admin@peering# ping 2001::a:1 source-address 2001::f:0
PING 2001::a:1 56 data bytes
64 bytes from 2001::a:1 icmp_seq=1 hlim=63 time=10.4ms.
64 bytes from 2001::a:1 icmp_seq=2 hlim=63 time=10.5ms.
64 bytes from 2001::a:1 icmp_seq=3 hlim=63 time=10.4ms.
64 bytes from 2001::a:1 icmp_seq=4 hlim=63 time=9.55ms.
64 bytes from 2001::a:1 icmp_seq=5 hlim=63 time=7.84ms.

---- 2001::a:1 PING Statistics ----
5 packets transmitted, 5 packets received, 0.00% packet loss
round-trip min = 7.84ms, avg = 9.75ms, max = 10.5ms, stddev = 1.02ms
```

```bash
ssh admin@nid

A:admin@nid# /ping 2001::f:0 source-address 2001::a:1 router-instance "twamp" 
PING 2001::f:0 56 data bytes
64 bytes from 2001::f:0 icmp_seq=1 hlim=63 time=10.8ms.
64 bytes from 2001::f:0 icmp_seq=2 hlim=63 time=11.0ms.
64 bytes from 2001::f:0 icmp_seq=3 hlim=63 time=10.1ms.
64 bytes from 2001::f:0 icmp_seq=4 hlim=63 time=11.0ms.
64 bytes from 2001::f:0 icmp_seq=5 hlim=63 time=9.43ms.

---- 2001::f:0 PING Statistics ----
5 packets transmitted, 5 packets received, 0.00% packet loss
round-trip min = 9.43ms, avg = 10.5ms, max = 11.0ms, stddev = 0.623ms
```

## Save configurations

To save additional changes to the topology, make sure to run script below which will copy all config.cfg files to the ./config directory.
```bash
./save_config.sh
```

## Cleanup

To destroy the lab:
```bash
sudo containerlab destroy -t topo.clab.yml
```
