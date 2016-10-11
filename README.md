# ext4-analyze-for-hot-extension.sh
#
#
#
# This script will help you to do an hot extend ext4 FS in an LV (LVM) :
#
# It analyze journal and other options to know if or if not possible to do it !
# 
# Who hasn't extend an FS in serveral time and to be mandatory to umount FS and so stop process to do it , maybe it's better to know if yes or no, we can do it mounted or umounted...
#
# Don't hesitate to contribute... you are welcome
# 
# TODO :
#  - test to find the highest value of certain value of journal or to find an more formal method to obtain limits.
#  
