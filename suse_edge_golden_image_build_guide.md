# Building a SUSE Edge Golden Image
## Scale Computing VM-based Remote Edge Deployment

*Exported from the deployment guidance discussed in chat.*

**Purpose:** This guide captures the exact steps to build a production-oriented SUSE Edge golden image using Edge Image Builder (EIB) for phone-home onboarding into Rancher Elemental.

## Assumptions

- The management cluster already has Rancher and Elemental installed.
- A MachineRegistration object has been created and you can retrieve its registration URL.
- The base image is SUSE Linux Micro 6.2 and the builder version is Edge Image Builder 1.3.3.
- The target is a Scale Computing VM deployment with the image installing to `/dev/vda`.

## Build Procedure

### 1. Prepare prerequisites

- A Linux build host with Podman installed.
- The SUSE Linux Micro 6.2 base ISO.
- Your production `eib-config.yaml`.
- A working MachineRegistration object in Rancher/Elemental.

### 2. Create the build workspace

```bash
export EIB_DIR=$HOME/eib-scale-prod

mkdir -p $EIB_DIR/base-images
mkdir -p $EIB_DIR/elemental
mkdir -p $EIB_DIR/network
mkdir -p $EIB_DIR/files
```

### 3. Copy the base ISO and config files

```bash
cp /path/to/SL-Micro.x86_64-6.2-Base-SelfInstall-GM.install.iso $EIB_DIR/base-images/
cp /path/to/eib-config.yaml $EIB_DIR/
cp /path/to/_all.yaml $EIB_DIR/network/
```

### 4. Fetch the Elemental registration config

```bash
REGISURL=$(kubectl get machineregistration scale-remote-edge -n fleet-default -o jsonpath='{.status.registrationURL}')
echo $REGISURL

curl "$REGISURL" -o $EIB_DIR/elemental/elemental_config.yaml
```

### 5. Verify the key EIB fields

```yaml
apiVersion: 1.3
image:
  imageType: iso
  arch: x86_64
  baseImage: SL-Micro.x86_64-6.2-Base-SelfInstall-GM.install.iso
  outputImageName: suse-edge-scale-remote-prod.iso
operatingSystem:
  isoConfiguration:
    installDevice: /dev/vda
```

### 6. Pull the Edge Image Builder container

```bash
podman pull registry.suse.com/edge/3.5/edge-image-builder:1.3.3
```

### 7. Run the image build

```bash
podman run --privileged --rm -it \
  -v $EIB_DIR:/eib \
  registry.suse.com/edge/3.5/edge-image-builder:1.3.3 \
  build --definition-file eib-config.yaml
```

### 8. Validate the output

- Confirm the generated ISO exists in the build directory with the name defined in `outputImageName`.
- Attach the ISO to the Scale VM and boot from it.
- After install and reboot, verify the node phones home and appears in Rancher Elemental inventory.

## Recommended Folder Layout

```text
/eib
  ├── eib-config.yaml
  ├── base-images/
  │   └── SL-Micro.x86_64-6.2-Base-SelfInstall-GM.install.iso
  ├── elemental/
  │   └── elemental_config.yaml
  ├── network/
  │   └── _all.yaml
  └── files/
```

## Common Failure Points

- Wrong base ISO filename in `eib-config.yaml`.
- Incorrect install device for the VM.
- Registration URL not fetched correctly.
- YAML syntax issues in the EIB definition or network files.
- Rancher endpoint, DNS, or certificate trust problems.
- TPM behavior mismatch for VM-based registration.

## Source Notes

This guide is based on the SUSE Edge 3.5 documentation for Edge Image Builder, remote host onboarding with Elemental, Edge networking, and Elemental TPM guidance.


kubectl create namespace cattle-elemental-system

helm install elemental-operator-crds \
  oci://registry.suse.com/rancher/elemental-operator-crds-chart \
  --version 1.8.1 \
  -n cattle-elemental-system

helm install elemental-operator \
  oci://registry.suse.com/rancher/elemental-operator-chart \
  --version 1.8.1 \
  -n cattle-elemental-system
