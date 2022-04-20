First Program test framebuffer to raspberry pi 3B+  64 bits : frametest164

result example :

id : vc4drmfb  size : 768000

Variables info : 800 * 480  Bits par pixel : 16

Second programm test :  frametest364   

Displays the blue color on half of the screen. Overwrites the standard screen of the raspberry pi

20 avril 2022 Pour le raspberry pi 3 correction par mise en commentaire dans /boot/config.txt 

  de l'option #dtoverlay=vc4-fkms-v3d
  
id : BCM2708 FB  size : 1536000

Variables info : 800 * 480  Bits par pixel : 32


