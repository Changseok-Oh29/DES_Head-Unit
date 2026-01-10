Raspberry Pi 4 USB Boot Loop Fix (Yocto Kirkstone)
Problem Description
The Raspberry Pi 4 is stuck in a boot loop during the U-Boot phase if any USB device (keyboard, mouse, dongle) is plugged in. The logs show: BUG at drivers/usb/host/xhci-ring.c:503/abort_td()!

This is a known bug in U-Boot v2022.01 (used in Kirkstone) where the XHCI driver panics instead of gracefully handling a timeout during USB device probing.

Required Task
Create a patch for u-boot-raspberrypi that converts the BUG() call into a non-fatal warning, allowing the boot sequence to continue into the Linux kernel.

1. The Patch File
Create this file at: recipes-bsp/u-boot/files/0001-xhci-fix-abort-td-panic.patch

Diff

--- a/drivers/usb/host/xhci-ring.c
+++ b/drivers/usb/host/xhci-ring.c
@@ -499,10 +499,14 @@
 	xhci_queue_command(ctrl, NULL, udev->slot_id, ep_index, TRB_STOP_RING);
 	event = xhci_wait_for_event(ctrl, TRB_TRANSFER, false);
-	field = le32_to_cpu(event->trans_event.flags);
-	BUG_ON(TRB_TO_SLOT_ID(field) != udev->slot_id);
-	BUG_ON(TRB_TO_EP_INDEX(field) != ep_index);
-	BUG_ON(GET_COMP_CODE(le32_to_cpu(event->trans_event.transfer_len
-				!= COMP_STOP)));
+	if (event) {
+		field = le32_to_cpu(event->trans_event.flags);
+		if (TRB_TO_SLOT_ID(field) != udev->slot_id ||
+		    TRB_TO_EP_INDEX(field) != ep_index) {
+			printf("XHCI: Unexpected event during abort, ignoring...\n");
+		}
+	} else {
+		printf("XHCI: Timeout during abort_td, ignoring...\n");
+	}
 	xhci_acknowledge_event(ctrl);
2. The Bitbake Append File
Create or update this file at: recipes-bsp/u-boot/u-boot-raspberrypi_%.bbappend

코드 스니펫

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-xhci-fix-abort-td-panic.patch"
3. Execution Commands
After the files are in place, the agent should run:

bitbake -c cleansstate u-boot-raspberrypi

bitbake u-boot-raspberrypi

If successful, rebuild the image: bitbake <your-image-name>