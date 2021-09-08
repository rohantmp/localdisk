# Testing libstoragemgmt plugin support on HPE smart arrays

Build the image:
(replace docker.io/rohantmp/lsm_hpsa:latest with your image tag in all commands, or skip the build and directly use the image)
```
docker build -f Dockerfile.lsm_hpsa . -t docker.io/rohantmp/lsm_hpsa:latest
```
Run it on the HP machine:
```
podman run --privileged --pid=host --user root $(for i in dev sys proc ;do echo --mount type=bind,source=/$i,target=/$i;done)  docker.io/rohantmp/lsm_hpsa:latest list --type=DISKS
```
Example output:
```
ID                 | Name                       | Type | Size | Status | System ID      | SCSI VPD 0x83 | Disk Paths | Revolutions Per Minute | Link Type
---------------------------------------------------------------------------------------------------------------------------------------------------------
BTHV603000TL400NGN | ATA     MK0400GEYKD 1I:1:2 | SSD  | 0    | OK     | PDNNK0BRH571XZ |               |            | Non-Rotating Medium    | PATA/SATA
17V3K9U7F1EA       | ATA     MB1000GDUNU 1I:1:1 | SATA | 0    | OK     | PDNNK0BRH571XZ |               |            | 7200                   | PATA/SATA
```
List systems and note the ID (in this case it's `PDNNK0BRH571XZ`):
```
podman run --privileged --pid=host --user root $(for i in dev sys proc ;do echo --mount type=bind,source=/$i,target=/$i;done)  docker.io/rohantmp/lsm_hpsa:latest list --type=SYSTEMS
```
Example output:
```
ID             | Name                                 | Status | Info                      | FW Ver | Mode    | Read Cache Percentage
-------------------------------------------------------------------------------------------------------------------------------------
PDNNK0BRH571XZ | Smart HBA H240 in Slot 1 (RAID Mode) | OK     |  "Controller Status"=[OK] | 4.52-0 | HW RAID | -1      
```
Use the id from the previous step to list capablities for each system:
```
podman run --privileged --pid=host --user root $(for i in dev sys proc ;do echo --mount type=bind,source=/$i,target=/$i;done) docker.io/rohantmp/lsm_hpsa:latest capabilities --sys=PDNNK0BRH571XZ                                    
```
Example output:
```
--------------------------------------------------------------
BATTERIES                                        | SUPPORTED  
DISKS                                            | SUPPORTED  
DISK_LOCATION                                    | SUPPORTED  
DISK_VPD83_GET                                   | SUPPORTED  
POOL_MEMBER_INFO                                 | SUPPORTED  
SYS_FW_VERSION_GET                               | SUPPORTED  
SYS_MODE_GET                                     | SUPPORTED  
VOLUMES                                          | SUPPORTED  
VOLUME_CACHE_INFO                                | SUPPORTED  
VOLUME_DELETE                                    | SUPPORTED  
VOLUME_ENABLE                                    | SUPPORTED  
VOLUME_LED                                       | SUPPORTED  
VOLUME_PHYSICAL_DISK_CACHE_UPDATE                | SUPPORTED  
VOLUME_PHYSICAL_DISK_CACHE_UPDATE_SYSTEM_LEVEL   | SUPPORTED  
VOLUME_RAID_CREATE                               | SUPPORTED  
VOLUME_RAID_INFO                                 | SUPPORTED  
VOLUME_READ_CACHE_POLICY_UPDATE                  | SUPPORTED  
VOLUME_READ_CACHE_POLICY_UPDATE_IMPACT_WRITE     | SUPPORTED  
VOLUME_WRITE_CACHE_POLICY_UPDATE_AUTO            | SUPPORTED  
VOLUME_WRITE_CACHE_POLICY_UPDATE_IMPACT_READ     | SUPPORTED  
VOLUME_WRITE_CACHE_POLICY_UPDATE_WB_IMPACT_OTHER | SUPPORTED  
VOLUME_WRITE_CACHE_POLICY_UPDATE_WRITE_BACK      | SUPPORTED  
VOLUME_WRITE_CACHE_POLICY_UPDATE_WRITE_THROUGH   | SUPPORTED  
ACCESS_GROUPS                                    | UNSUPPORTED
ACCESS_GROUPS_GRANTED_TO_VOLUME                  | UNSUPPORTED
```

# localdisk for direct attached storage
Example project showing how the libstoragemgmt-golang package can be used to interact with the libstoragemgmt library. The libstoragemgmt library (LSM), provides interfaces to perform common storage tasks across a variety of backends. This example code, focuses solely on localdisk interaction.

Obviously, as an admin you can just run the lsmcli commands directly, but this project shows how you can interact with libstoragemgmt programmatically for automation, or platform integration.


## Building the source using docker (does not require installing libstoragemgmt or any dependencies):

Build and cache base image so that the final image can be rebuilt without redownloading all the packages:
```
docker build --target builder -f Dockerfile . -t localdisk-builder
```
Build the final image. If pushing to your own repo, replace localdisk with <registry>/<username>/localdisk (e.g. docker.io/my-username/localdisk)
```
docker build --cache-from localdisk-builder -f Dockerfile . -t localdisk
```

## Running the tool using docker (SMART apis require a privileged container/root)

```
docker run  --privileged --pid=host --user root $(for i in dev sys proc ;do echo --mount type=bind,source=/$i,target=/$i;done) localdisk -list
```
## Running the tool on a specific node in kubernetes:
Clone this repo:
```
git clone https://github.com/rohantmp/localdisk.git;
cd localdisk;
```
Get nodes and choose one with storage:
```
oc get node;
```
```
NAME    STATUS     ROLES           AGE   VERSION
node0   Ready      master,worker   55d   v1.20.0+7d0a2b2
node1   NotReady   master,worker   55d   v1.20.0+7d0a2b2
node2   Ready      master,worker   55d   v1.20.0+7d0a2b2
```
Apply job (substitute nodename):
```
oc delete job,po -l name=localdisk;
NODENAME=node0;
sed testjob.yaml -e "s/HOSTNAME/${NODENAME}/g"|oc apply -f -;
```
Get logs
```
oc wait job -l name=localdisk --for=condition=complete --timeout=3m; oc logs -l name=localdisk
```
Example Output:
```
version: "c97916e2f29de80f019d32ab35638f53d7ba8e27"
Device Path        Type Serial Number              Size Sector  Transport   RPM Bus Speed       IDENT        FAIL  Health           Vendor            Model Revision                 wwid
/dev/sda          Flash 000e2ee7f4c43fde2700061189f0a7ce       893.8 GiB    512 Not supported by LSM     0         0 Unavailable Unavailable Unknown             DELL  PERC H740P Mini     5.13 naa.62cea7f08911060027de3fc4f4e72e0e
/dev/nvme0n1        HDD                             0 B    4KN    Unknown    -1         0 Unavailable Unavailable    Good                  Dell Express Flash NVMe P4610 1.6TB SFF                              
/dev/nvme1n1        HDD                             0 B    4KN    Unknown    -1         0 Unavailable Unavailable    Good                  Dell Express Flash NVMe P4610 1.6TB SFF                              
/dev/nvme2n1        HDD                             0 B    4KN    Unknown    -1         0 Unavailable Unavailable    Good                  Dell Express Flash NVMe P4610 1.6TB SFF                              
```


---
## Without Docker:

## Prerequisites
1. For build and testing you need the following rpms installed on your system
- libstoragemgmt
- libstoragemgmt-devel
2. For running on a host the host must have the libstoragemgmt rpm installed.  

3. To run either lsmcli or this code, the user requires r/w privileges to the device (root normally)  

## Build
The localdisk package within libstoragemgmt-golang uses **cgo** to interact with the libstoragemgmt api, so to build you need to point the linker at the local machines install location of the libstoragemgmt library  
e.g.

```
# CGO_LDFLAGS=/usr/lib64/libstoragemgmt.so go build -o localdisk
```
or 
```
make build-localdisk
```

## Running the tool
1. Example options
```
[root@srv-01 bin]# localdisk -h
Usage of localdisk:
  -fail-led-off string
    	de-activate fail LED on a given device
  -fail-led-on string
    	activate fail LED on a given device
  -list
    	list all local disks
  -show string
    	show a specific disk matching given /dev name

```
2. Turn on fail LED
```
localdisk -fail-led-on /dev/sda
```
3. Turn off fail LED
```
localdisk -fail-led-off /dev/sda
```

## Output Examples
1. Disk list
```
[root@srv-01 ~]# localdisk -list
Device Path        Type Serial Number              Size Sector  Transport   RPM Bus Speed       IDENT        FAIL  Health           Vendor            Model Revision                 wwid
/dev/sda            HDD 15P0A0R0FRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082ba631
/dev/sdb            HDD 15P0A0YFFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082bbbf9
/dev/sdk            HDD 15P0A0ONFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082b989d
/dev/sdl            HDD 15P0A0YBFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082bb9d1
/dev/sdm          Flash BTWL452503K7480QGN       447.1 GiB   512e   IDE/SATA     0      6000     UNKNOWN         OFF Unknown              ATA INTEL SSDSC2BB48     DL13 naa.55cd2e404b753fb0
/dev/sdn          Flash BTWL452503PJ480QGN       447.1 GiB   512e   IDE/SATA     0      6000     UNKNOWN         OFF Unknown              ATA INTEL SSDSC2BB48     DL13 naa.55cd2e404b754043
/dev/sdo          Flash BTWL452503K2480QGN       447.1 GiB   512e   IDE/SATA     0      6000     UNKNOWN         OFF Unknown              ATA INTEL SSDSC2BB48     DL13 naa.55cd2e404b753fab
/dev/sdp          Flash BTWL452503PF480QGN       447.1 GiB   512e   IDE/SATA     0      6000     UNKNOWN         OFF Unknown              ATA INTEL SSDSC2BB48     DL13 naa.55cd2e404b754040
/dev/sdc            HDD 15R0A08WFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.500003960831c74d
/dev/sdd            HDD 15R0A07DFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.500003960831bfbd
/dev/sde            HDD 15P0A0QDFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082ba3a1
/dev/sdf            HDD 15R0A064FRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.500003960831b065
/dev/sdg            HDD 15P0A0QWFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082ba5fd
/dev/sdh            HDD 15P0A0O8FRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082b9675
/dev/sdi            HDD 15P0A0RFFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.50000396082ba709
/dev/sdj            HDD 15R0A07PFRD6          279.4 GiB    512        SAS 10000      6000     UNKNOWN         OFF    Good          TOSHIBA       AL13SEB300     DE0D naa.500003960831c051

```
2. Turning the fail LED ON
```
[root@srv-01 bin]# localdisk -fail-led-on /dev/sdf
[root@srv-01 bin]# localdisk -show /dev/sdf
Device Path    : /dev/sdf
Type           : HDD
Serial Number  : 15R0A064FRD6
Size           : 279.4 GiB
Sector Format  : 512
Transport      : SAS
RPM            : 10000
Bus Speed      : 6000
IDENT LED      : UNKNOWN
FAIL LED       : ON                   <-----
Health         : Good
Vendor         : TOSHIBA
Model          : AL13SEB300
Revision       : DE0D
wwid           : naa.500003960831b065
```
3. Turning the fail LED OFF
```
[root@srv-01 ~]# localdisk -fail-led-off /dev/sdf
[root@srv-01 ~]# localdisk -show /dev/sdf
Device Path    : /dev/sdf
Type           : HDD
Serial Number  : 15R0A064FRD6
Size           : 279.4 GiB
Sector Format  : 512
Transport      : SAS
RPM            : 10000
Bus Speed      : 6000
IDENT LED      : UNKNOWN
FAIL LED       : OFF                  <-----
Health         : Good
Vendor         : TOSHIBA
Model          : AL13SEB300
Revision       : DE0D
wwid           : naa.500003960831b065

```
  
After running this process, the changes to the fault LED could be seen in the server's BMC  
  
![LED-Changes](images/fault-led-test.png)

The CLI and GUI output shown above is from an old Dell r730 server, running RHEL7.4. It's reasonable to expect a more modern server to provide better information and support for features like disk IDENT and flash drive health.
