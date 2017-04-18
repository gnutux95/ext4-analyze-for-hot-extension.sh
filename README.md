# ext4-analyze-for-hot-extension.sh
#
#
#
# This script will help you to do an hot extend ext4 FS in an LV (LVM) / tested under RHEL/CentOS 6.2, 6.4 and 6.6 :
#
# It analyze journal to find, determine what was the first FS near Size, if GDT present or not and other options to know if or if not possible to do it !
# In entreprise environment, this is important to avoid stop production/application to extend and planified maintenance operation...
# 
# Who hasn't extend an FS in serveral time and to be mandatory to umount FS and so stop process to do it , maybe it's better to know if yes or no, we can do it mounted or umounted...
#
# Don't hesitate to contribute... you are welcome
# 
# TODO :
#  - test to find the highest value of certain value of journal or to find an more formal method to obtain limits.
#  - help to determine max ONLINE Extend with GDT (understand details of operations which touch 1000x GDT - mke2fs afford -E with inode reservation to GDT but we aren't in Red Hat and other distributions standard... by example) 
