[README in English](https://github.com/OKS-Tech-Japan/spehat_driver/blob/main/README_en.md)

# SPE HAT Linux driver for Raspberry Pi

このリポジトリは、弊社製品SPE HATに搭載しているAnalogDevices社10BASE-T1L MAC PHY、ADIN1110のLinuxドライバを元に改変したものです。

改変元：  
https://github.com/analogdevicesinc/linux/tree/master/drivers/net/ethernet/adi  
commit b765a3ffb08051204405013a0ed655e7e3337f32

# SPE HATについて
SPE HATは弊社OKS-TECHが開発した、Raspberry Pi用10BASE-T1Lボードです。

10BASE-T1L(IEEE 802.3cg-2019)は従来からあるRS485等のフィールドネットワークを置き換える新しい規格で、 全ての産業用ネットワークをEthernet化することができるようになります。また規格上の伝送距離は1000mで、10Mbpsの伝送速度と52Wまでの電力供給をサポートしています。 本質安全防爆にも規格レベルで対応しており、将来プラント等での導入が期待されています。

SPE HATの詳しい内容については弊社Webサイトをご覧ください。  
https://www.okstech.co.jp/products/spe_hat.html

# 変更点
- SPE HATで不要なFDBハードウェアオフロード部分の削除

    SPE HATは端末でこの機能が不要なのにもかかわらず、改変元のコードをそのままビルドするにはカーネルコンフィグでSwitch Device Suportを有効にする必要があります。つまりカーネル自体の再ビルド・再インストールが必要になります。この修正の本来の目的は、それらを不要にすることです。この修正により、すでに稼働しているカーネルはそのままに、モジュールだけをビルドしてインストールすることができます。Raspberry Pi OSの場合、ビルドに必要なものはkernel-headersのみとなります。

- LED1ポートの動作の変更

    ADIN1110のLED1ポートはリセット時に無効ですが、振幅が2.4Vppのモードで点灯するように設定を追加しています。

- DeviceTree Ovarlay用dts(dtso)ファイルの追加

# ビルド・インストール手順
Raspberry Pi OS上でのビルドとインストールについて手順を示します。他のLinuxディストリビューションでのビルド、またクロスビルドについては記載していません。

1. カーネルヘッダをインストールします  
    ```
    $ sudo apt install raspberrypi-kernel-headers
    ```
2. リポジトリをクローンします  
    ```
    $ git clone https://github.com/OKS-Tech-Japan/spehat_driver.git
    ```
3. ディレクトリを移動し、mekeします  
    ```
    $ cd spehat_driver
    $ make
    ```
4. ビルドしたkoファイルを/lib/modulesにコピーします。koファイルをxzで圧縮しても構いません。  
    ```
    $ sudo cp adin1110.ko /lib/modules/$(uname -r)/kernel/drivers/net
    ```
5. カーネルモジュールの依存関係リストを更新します  
    ```
    $ sudo depmod -a
    ```
6. DeviceTree Overlay用のファイルを生成します  
    ```
    $ dtc -@ -I dts -O dtb -o adin1110.dtbo dts/bcm2835_adin1110.dtso
    ```
7. Overlay用ファイルを/boot/overlaysへコピーします  
    ```
    $ sudo cp adin1110.dtbo /boot/overlays
    ```
8. /boot/config.txtに下記の行を追加します  
    ```
    dtoverlay=adin1110
    ```
9. raspi-configを実行してSPIを有効にします  
    ```
    $ sudo raspi-config
    Interface Options -> SPI
    ```
10. MACアドレスを再設定します。  
    下記の内容の /etc/systemd/network/00-spe-hat-mac.link を作成します。  
    ```
    [Match]
    MACAddress=ca:2f:b7:10:23:63
    [Link]
    MACAddress=02:00:00:00:00:01
    ```

    SPE HATにはMACアドレスが存在しません。起動時に設定されるMACアドレスはDeviceTreeで設定されているもので、このアドレスはAnalogDevices社のADIN1110 Wiki記載のものを使用しています。複数のSPE HATを接続する場合は、手動でLAA(Locally Administered Address)を設定してください。LAAはネットワーク管理者が設定するためのアドレスで、ローカルネットワークの環境で使用できます。
    
    LAAアドレス範囲は次の通りです。  
    x2‑xx‑xx‑xx‑xx‑xx  
    x6‑xx‑xx‑xx‑xx‑xx  
    xA‑xx‑xx‑xx‑xx‑xx  
    xE‑xx‑xx‑xx‑xx‑xx

    ADIN1110 10BASE-T1L MAC-PHY Linux Driver  
    https://wiki.analog.com/resources/tools-software/linux-drivers/net-mac-phy/adin1110
    

11. Raspberry Piを再起動します  
    ```
    $ sudo reboot
    ```
12. 起動後、ipコマンドで新しいethXが出来ていることを確認してください。  
    ```
    $ ip link show
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
        link/ether 02:00:00:00:00:01 brd ff:ff:ff:ff:ff:ff permaddr ca:2f:b7:10:23:63
    3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DORMANT group default qlen 1000
        link/ether b8:27:eb:cc:24:a4 brd ff:ff:ff:ff:ff:ff
    ```

# 謝辞

ADIN1110用Linuxドライバを公開されているAnalogDevices社、また作者であるAlexandru Tachici氏に感謝いたします。
