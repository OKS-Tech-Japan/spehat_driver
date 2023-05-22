[日本語 README](https://github.com/OKS-Tech-Japan/spehat_driver/blob/main/README.md)

# SPE HAT Linux driver for Raspberry Pi

This repository is modified for SPE HAT based on AnalogDevices 10BASE-T1L MAC PHY, ADIN1110 Linux driver.

Original：  
https://github.com/analogdevicesinc/linux/tree/master/drivers/net/ethernet/adi  
commit b765a3ffb08051204405013a0ed655e7e3337f32


# About SPE HAT
SPE HAT is an expansion board that can turn Raspberry Pi into a single pair Ethernet 10BASE-T1L terminal.

10BASE-T1L (IEEE 802.3cg-2019) are new standards to replace conventional field networks such as RS485, enabling all industrial networks to be Ethernetized. The standard transmission distance is 1000m, and it supports a transmission speed of 10Mbps and power supply up to 52W by PoDL(SPoE). It also supports intrinsically safe and is expected to be introduced in plants in the future.

For more information, please visit our website.  
https://www.okstech.co.jp/en/products/spe_hat.html

# Changes
- Remove FDB offloading.  
    Even though SPE HAT does not need this function, it is necessary to enable Switch Device Support in the kernel config to build the original code as it is. In other words, you will need to rebuild and reinstall the kernel. The purpose of this fix is to make them unnecessary.This fix allows you to build and install just the module while leaving the already running kernel intact. For the Raspberry Pi OS, you only need to install kernel headers to build.

- Change LED1 port function.  
    By default setting, the ADIN1110's LED1 port is disabled at reset. A setting is added so that LED1 lights in the mode with an amplitude of 2.4Vpp.

- Add dts(dtso) file for DeviceTree Ovarlay.

# How to build and install
Here are the steps for building and installing on Raspberry Pi OS. It does not cover building on other Linux distributions or cross-building.

1. Install kernel headers.
    ```
    $ sudo apt install raspberrypi-kernel-headers
    ```
2. Clone the repository.
    ```
    $ git clone https://github.com/OKS-Tech-Japan/spehat_driver.git
    ```
3. Change directory and make.
    ```
    $ cd spehat_driver
    $ make
    ```
4. Copy the built ko file to /lib/modules. You can compress ko files with xz.
    ```
    $ sudo cp adin1110.ko /lib/modules/$(uname -r)/kernel/drivers/net
    ```
5. Update list of kernel module dependency.
    ```
    $ sudo depmod -a
    ```
6. Generate files for DeviceTree Overlay.
    ```
    $ dtc -@ -I dts -O dtb -o adin1110.dtbo dts/bcm2835_adin1110.dtso
    ```
7. Copy Overlay files to /boot/overlays.
    ```
    $ sudo cp adin1110.dtbo /boot/overlays
    ```
8. Add the following line to /boot/config.txt.
    ```
    dtoverlay=adin1110
    ```
9. Run raspi-config to enable SPI.
    ```
    $ sudo raspi-config
    Interface Options -> SPI
    ```
10. Set MAC address.  
    Create /etc/systemd/network/00-spe-hat-mac.link with the following content.
    ```
    [Match]
    MACAddress=ca:2f:b7:10:23:63
    [Link]
    MACAddress=02:00:00:00:00:01
    ```
    
    SPE HAT does not have a MAC address. The MAC address at startup is set in DeviceTree, and this address uses the one described in ADIN1110 Wiki of AnalogDevices. When connecting multiple HATs, set the LAA (Locally Administered Address) manually. LAA is an address by a network administrator and can be used in a local network.

    The LAA address ranges are as follows:  

    x2‑xx‑xx‑xx‑xx‑xx  
    x6‑xx‑xx‑xx‑xx‑xx  
    xA‑xx‑xx‑xx‑xx‑xx  
    xE‑xx‑xx‑xx‑xx‑xx

    ADIN1110 10BASE-T1L MAC-PHY Linux Driver  
    https://wiki.analog.com/resources/tools-software/linux-drivers/net-mac-phy/adin1110
    

11. Reboot.
    ```
    $ sudo reboot
    ```
12. After booting, use the ip command to confirm that a new ethX has been created.
    ```
    $ ip link show
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
        link/ether 02:00:00:00:00:01 brd ff:ff:ff:ff:ff:ff permaddr ca:2f:b7:10:23:63
    3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DORMANT group default qlen 1000
        link/ether b8:27:eb:cc:24:a4 brd ff:ff:ff:ff:ff:ff
    ```

# Acknowledgments

Thanks to AnalogDevices for publishing the original Linux driver and the original author, Alexandru Tachici.
