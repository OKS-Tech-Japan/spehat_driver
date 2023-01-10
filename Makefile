# SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
#
# Makefile for the Analog Devices network device drivers.
#

obj-m := adin1110.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

