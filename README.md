# Nokia TWAMP Test Lab with Containerlab

This is a Nokia lab demonstrating TWAMP (Two-Way Active Measurement Protocol) testing between network devices using Nokia SR OS simulators. The lab includes a complete network topology with TWAMP originator and reflector endpoints for performance measurement testing.

![Network Topology](topologyv3.png)

## Overview

The lab implements a TWAMP test scenario where:
- **Originator**: Peering Router (7750 SR-1) initiates TWAMP tests
- **CPE (Reflector)**: Nokia IXR-e2c device that reflects TWAMP packets back to the originator
- **Network Path**: Complete L2/L3 network infrastructure between originator and CPE

The TWAMP session measures round-trip delay and packet loss between the originator (172.20.20.108) and CPE endpoints through a realistic network topology including aggregation, service provider edge, and core networking elements.

## Lab Components

### Network Devices
- **ce**: Customer Edge (Nokia IXR-e2c)
- **cpe**: Customer Premises Equipment (Nokia IXR-e2c) - TWAMP Reflector
- **agg**: Aggregation Router (Nokia IXR-e2)
- **spe**: Service Provider Edge (Nokia SR-1)
- **coi-l2**: Core of Internet L2 (Nokia SR-1)
- **coi-l3**: Core of Internet L3 (Nokia SR-1)
- **peering**: Peering Router (Nokia SR-1)

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
- **Session Name**: `toCPE`
- **Test Direction**: Peering Router (172.20.20.107) → CPE (172.20.20.102)
- **Source Address**: `2001::f:0` (Originator)
- **Destination Address**: `2001::a:1` (CPE Reflector)
- **UDP Port**: 64364
- **Test ID**: 100708
- **Interval**: 10 seconds (10000ms)
- **Pad Size**: 5 bytes

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
```bash
gnmic -a 172.20.20.107 -u grpc -p telemetry --insecure subscribe \
  --path "/state/oam-pm/session[session-name=toCPE]/ip/twamp-light/statistics/delay/measurement-interval[duration=raw]/number[mi-number=1]/bin-type[bin-metric=fd]/round-trip/average" \
  | grep average
```

If gnmic does not provide any results, use the debug option:
```bash
gnmic -a 172.20.20.107 -d -u grpc -p telemetry --insecure subscribe \
  --path "/state/oam-pm/session[session-name=toCPE]/ip/twamp-light/statistics/delay/measurement-interval[duration=raw]/number[mi-number=1]/bin-type[bin-metric=fd]/round-trip/average" \
  | grep average
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
│   ├── peering.partial.txt    # TWAMP originator config
│   ├── cpe.partial.txt        # TWAMP reflector config
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
```bash
ssh admin@originator

A:admin@peering# show oam-pm statistics session "toCPE" twamp-light meas-interval raw 

------------------------------------------------------------------------------
Start (UTC)       : 2025/09/11 15:42:05          Status          : in-progress
Elapsed (seconds) : 783                          Suspect         : yes
Frames Sent       : 641                          Frames Received : 641
------------------------------------------------------------------------------
===============================================================================
TWAMP-LIGHT DELAY STATISTICS

----------------------------------------------------------------------------
Bin Type     Direction     Minimum (us)   Maximum (us)   Average (us)   EfA
----------------------------------------------------------------------------
FD           Forward               4112          10369           5601    no
FD           Backward              3039           7901           4371    no
FD           Round Trip            7554          15000           9973    no
FDR          Forward                  0           5693           1334    no
FDR          Backward                 0           4862           1135    no
FDR          Round Trip               0           6768           2201    no
IFDV         Forward                  1           4825            674    no
IFDV         Backward                 0           3898            442    no
IFDV         Round Trip               3           5839            887    no
----------------------------------------------------------------------------
EfA = yes: one or more bins configured to be Excluded from the Average calc.

---------------------------------------------------------------
Frame Delay (FD) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us            74           602             0
1            5000 us           566            39           383
2           10000 us             1             0           258
---------------------------------------------------------------

---------------------------------------------------------------
Frame Delay Range (FDR) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us           639           641           634
1            5000 us             2             0             7
---------------------------------------------------------------

---------------------------------------------------------------
Inter-Frame Delay Variation (IFDV) Bin Counts
---------------------------------------------------------------
Bin      Lower Bound       Forward      Backward    Round Trip
---------------------------------------------------------------
0               0 us           640           640           637
1            5000 us             0             0             3
---------------------------------------------------------------
===============================================================================
===============================================================================
TWAMP-LIGHT LOSS STATISTICS: NONE
===============================================================================
```

**Verify TWAMP reflector on CPE:**
```bash
ssh admin@cpe
A:admin@cpe# show router service-name twamp twamp-light 

-------------------------------------------------------------------------------
TWAMP-Light Reflector
-------------------------------------------------------------------------------
Admin State          : Up                      UDP Port         : 64364
IPv6 UDP Checksum 0  : Disallow                
Description          : (Not Specified)
Up Time              : 0d 00:13:27             
Test Frames Received : 667                     Test Frames Sent : 667
Type                 : TWAMP-Light             
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
TWAMP-Light Reflector Prefixes
-------------------------------------------------------------------------------
Prefix                                      Description
-------------------------------------------------------------------------------
2001::f:0/127                               
-------------------------------------------------------------------------------
No. of TWAMP-Light Reflector Prefixes: 1
-------------------------------------------------------------------------------
```

**Test network connectivity:**
IPv6 ping from Peering to CPE
```bash
ssh admin@originator
A:admin@peering# ping 2001::a:1 source-address 2001::f:0
PING 2001::a:1 56 data bytes
64 bytes from 2001::a:1 icmp_seq=1 hlim=63 time=8.96ms.
64 bytes from 2001::a:1 icmp_seq=2 hlim=63 time=9.36ms.
64 bytes from 2001::a:1 icmp_seq=3 hlim=63 time=10.2ms.
64 bytes from 2001::a:1 icmp_seq=4 hlim=63 time=9.09ms.
64 bytes from 2001::a:1 icmp_seq=5 hlim=63 time=9.38ms.

---- 2001::a:1 PING Statistics ----
5 packets transmitted, 5 packets received, 0.00% packet loss
round-trip min = 8.96ms, avg = 9.39ms, max = 10.2ms, stddev = 0.416ms
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
