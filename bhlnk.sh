#!/bin/bash
part=(system vendor product)
module=(vietsub fonts launcher gsm gsm_pd theme) 
dir=$(pwd)
bin="$dir/bin/linux"
bro="$dir/zip_temp"
chmod -R 777 $bin
chmod -R 777 $dir/bin
if [[ ! -f bin/gsm.img  ]]; then
	wget https://github.com/buihien224/host/releases/download/store/gsm.img
	mv gsm.img $dir/module
fi
config=0;
getszie()
{
	part_size[0]=$(find "system.img" -printf "%s")
	part_size[1]=$(find "vendor.img" -printf "%s")
	part_size[2]=$(find "product.img" -printf "%s")
}
zipfile()
{
cd $dir
echo "#############################"
echo "#     Unpack Zip rom .... #"
echo "#############################"
mkdir zip_temp
mkdir temp
unzip -t $zipname
unzip $zipname -d zip_temp
if [[ -f zip_temp/system.new.dat.br   ]]; then
	for ((i = 0 ; i < 3 ; i++)); do
		brotli --decompress zip_temp/"${part[$i]}.new.dat.br" -o zip_temp/"${part[$i]}.new.dat"
		python3 ./bin/sdat2img.py zip_temp/"${part[$i]}.transfer.list" zip_temp/"${part[$i]}.new.dat" "${part[$i]}.img"
		echo "extract "${part[$i]}.img" : done"
	done
	getszie
	if [[ -f "$bro/dynamic_partitions_op_list" ]]; then
		for ((i = 0 ; i < 3 ; i++)); do
		sed -i "s/${part_size[$i]}/"${part[$i]}_size"/g" "$bro/dynamic_partitions_op_list"
		done
	fi
	config=1
elif [[ -f zip_temp/payload.bin ]]; then
		cp "$dir/bin/payload_dumper.py" zip_temp
		cp "$dir/bin/update_metadata_pb2.py" zip_temp
		cd zip_temp
		python3 payload_dumper.py payload.bin
		for ((i = 0 ; i < 3 ; i++)); do
			mv "${part[$i]}.img" $dir
		done
		cd ..
		rm zip_temp/payload_dumper.py
		rm zip_temp/update_metadata_pb2.py
		config=2
else 
	echo "Type Rom is Not Support Yet !"
	exit
fi
	
}
######################
mkrw()
{
cd $dir
echo "#############################"
echo "#       READ-WRITE ....     #"
echo "#############################"
echo ""
echo "Get Parttion size ...."
echo ""
getszie
echo "Resize Parttion ...."
for ((i = 0 ; i < 3 ; i++)); do
	size=$(echo "${part_size[$i]} + 50000000" | bc)
	size1=$(echo "$size / 1024" | bc)
	echo "new "${part[$i]}.img" is : $size"
	e2fsck -f "${part[$i]}.img"
	resize2fs "${part[$i]}.img" $size1
	echo "${part[$i]}.img done"
done
echo ""
echo "Start remove Read-Only ...."
for ((i = 0 ; i < 3 ; i++)); do
	e2fsck -y -E unshare_blocks "${part[$i]}.img"
	echo ""${part[$i]}.img" : done"
done
}
##########
mount()
{
mkdir temp
echo "#############################"
echo "#        Mounting ....     #"
echo "#############################"
echo ""
echo "Enter your password to use Sudo ...."
for ((i = 0 ; i < 3 ; i++)); do
	mkdir temp/"${part[$i]}"
	sudo mount "${part[$i]}.img" temp/"${part[$i]}"
done
}
########
debloat()
{
cd $dir
echo "#############################"
echo "#       Debloating ....     #"
echo "#############################"
echo ""
echo "Debloating ...."
###########
sys=`cat $dir/module/debloat/system.txt`
ven=`cat $dir/module/debloat/vendor.txt`
echo "In System : "
cd $dir/temp/system/system
  for app in $sys; do
        sudo rm -rf "$app" 2>/dev/null
        echo "done"
  done
echo "In Vendor : "
cd $dir/temp/vendor
  for app in $ven; do
        sudo rm -rf "$app" 2>/dev/null
        echo "done"
  done
}
#########
#########
umount()
{
echo "#############################"
echo "#        Unmounting ....    #"
echo "#############################"
echo ""
cd $dir/temp
sleep 3
for ((i = 0 ; i < 3 ; i++)); do
	sudo umount "${part[$i]}"
	echo "Umount "${part[$i]}" :  done"
	sleep 3
done
}
##########
shrink ()
{
echo "#############################"
echo "#        Shrinking ....     #"
echo "#############################"
echo ""
cd $dir
sleep 1
for ((i = 0 ; i < 3 ; i++)); do
	resize2fs -f -M "${part[$i]}.img"
	echo "Shrink "${part[$i]}" :  done"
done
cd $dir
getszie
if [[ -f "$bro/dynamic_partitions_op_list" ]]; then
	for ((i = 0 ; i < 3 ; i++)); do
	sed -i "s/"${part[$i]}_size"/"${part_size[$i]}"/g" "$bro/dynamic_partitions_op_list"
	done
fi
}
cleanup()
{
	cd $dir
	if [[ -d "temp" ]]; then
		rm -r temp
		rm -r zip_temp
	fi
}
remove_source()
{
echo "#############################"
echo "#  remove source file ....   #"
echo "#############################"
echo ""
cd $dir/zip_temp
if [[ -f "system.new.dat.br" ]]; then
	rm firmware-update/vbmeta.img
	for ((i = 0 ; i < 3 ; i++)); do
		if [[ -f "${part[$i]}.new.dat.br" ]]; then
			rm "${part[$i]}.new.dat.br"
			rm "${part[$i]}.new.dat"
			rm "${part[$i]}.patch.dat"
			rm "${part[$i]}.transfer.list"
		fi
	done
fi
cd ..
}
permis()
{
  sudo chmod 644 $1
  sudo chown root $1
  sudo chgrp root $1
  echo "Set permission of $1 : done "
}
vietsub()
{
echo "#############################"
echo "#       VIETSUB-ING ....    #"
echo "#############################"
echo ""
	cd $dir/module
	echo "copy bhlnk's overlay and stuff"
for ((i = 0 ; i < 6 ; i++)); do
	mkdir "${module[$i]}_f"
	sudo mount "${module[$i]}.img" "${module[$i]}_f"
done
################################################
	echo "Adding Vietnamese Language"
	sudo cp -arf vietsub_f/overlay/. $dir/temp/vendor/overlay
  sudo cp -rf "thermal-normal.conf" $dir/temp/vendor/etc
  permis "$dir/temp/vendor/etc/thermal-normal.conf"
	sudo cp -rf "miui.apk" $dir/temp/system/system/app/miui
	permis "$dir/temp/system/system/app/miui/miui.apk"
	echo "Adding Roboto Fonts"
	sudo cp -arf fonts_f/system/fonts/. $dir/temp/system/system/fonts
	echo "Adding GSM and Crack Theme from https://yukongya.herokuapp.com"
	sudo cp -arf gsm_f/system/app/. $dir/temp/system/system/app
	sudo rm -rf $dir/temp/product/priv-app/GooglePlayServicesUpdater
	sudo cp -arf gsm_pd_f/priv-app/. $dir/temp/product/priv-app
	sudo cp -arf theme_f/system/app/MIUIThemeManager/. $dir/temp/system/system/app/MIUIThemeManager
	sudo rm -rf $dir/temp/system/system/app/MIUIThemeManager/oat
	sudo echo "on post-fs-data" >> $dir/temp/system/init.miui.rc
	sudo echo "    chmod 0731 /data/system/theme" >> $dir/temp/system/init.miui.rc
	#echo "Adding launcher"
	#sudo cp -arf launcher_f/system/priv-app/MiuiHome/. $dir/temp/system/system/priv-app/MiuiHome

	echo "done"

  for ((i = 0 ; i < 6 ; i++)); do
  	sudo umount "${module[$i]}_f"
  	rm -rf "${module[$i]}_f"
  done
	cd $dir
}
buildprop()
{
cd $dir/temp
cd system/system
sudo sed -i '/ro.product.locale/c\ro.product.locale=vi-VN' build.prop
sudo sed -i '/ro.miui.has_security_keyboard/c\ro.miui.has_security_keyboard=0' build.prop
sudo sed -i '$ a ro.miui.backdrop_sampling_enabled=true' build.prop
sudo sed -i '$ a persist.sys.allow_sys_app_update=true' build.prop
cd $dir/temp
cd vendor
sudo sed -i '/ro.vendor.cabc.enable/c\ro.vendor.cabc.enable=false' build.prop
sudo sed -i '/ro.vendor.bcbc.enable/c\ro.vendor.bcbc.enable=false' build.prop
sudo sed -i '/ro.vendor.dfps.enable/c\ro.vendor.dfps.enable=false' build.prop
sudo sed -i '/ro.vendor.smart_dfps.enable/c\ro.vendor.smart_dfps.enable=false' build.prop
sudo sed -i '$ a persist.sys.allow_sys_app_update=true' build.prop
}
repackz()
{
cd $dir
echo "#############################"
echo "#         Compress          #"
echo "#############################"
echo ""
echo "Compress to sparse img .... "
if [[ config -eq 2 ]]; then
	echo "making flashable file for A/B"
	
fi
for ((i = 0 ; i < 3 ; i++)); do
  echo "Compress "${part[$i]}.img" "
	img2simg "${part[$i]}.img" "s_${part[$i]}.img"
done
echo "Compress to new.dat .... "
for ((i = 0 ; i < 3 ; i++)); do
	echo "- Repack ${part[$i]}.img"
 	python3 ./bin/linux/img2sdat.py "s_${part[$i]}.img" -o $bro -v 4 -p "${part[$i]}"
done

#level brotli
echo "Compress to brotli .... "
#
for ((i = 0 ; i < 3 ; i++)); do
   	echo "- Repack ${part[$i]}.new.dat"
	brotli -6 -j -w 24 "$bro/${part[$i]}.new.dat" -o "$bro/${part[$i]}.new.dat.br"
	rm -rf "${part[$i]}.img"
	rm -rf "s_${part[$i]}.img"
	rm -rf "$bro/${part[$i]}.new.dat"
done
if [ -d $bro/META-INF ]; then
	echo "- Zipping"
	cp "$dir/bin/vbmeta.img" $bro
	[ -f ./MIUI_VIETSUB.zip ] && rm -rf ./MIUI_VIETSUB.zip
	7za a -tzip "$dir/vietsub_$zipname" $bro/*  
fi
if [ -f "$dir/vietsub_$zipname" ]; then
      echo "- Repack done"
else
      echo "- Repack error"
fi
}
superimg()
{
mkdir img_temp
echo "#############################"
echo "#          Super            #"
echo "#############################"
echo ""
echo "unpack super img .... "
echo ""
echo ""
echo "covert simg to img"
simg2img super.img raw.img
lpunpack raw.img img_temp
cd $dir/img_temp
		mv system_a.img $dir/system.img
		mv vendor_a.img $dir/vendor.img
		mv product_a.img $dir/product.img

echo "unpack superimg : done" 
}

boot()
{
	cd $dir/AIK-Linux
	cp $dir/zip_temp/boot.img $dir/AIK-Linux
	bash unpackimg.sh
	echo $1
	sudo cp -af $dir/module/avb/$1/. ramdisk
	bash repackimg.sh
	if [[ -d zip_temp ]]; 
	then
		mv -f image-new.img $dir/zip_temp/boot.img
	else mv -f image-new.img $dir/boot.img
	fi

}
cd $dir
cleanup
echo "#############################"
echo "#         STARTING ....     #"
echo "#############################"
echo ""
read -p "Press [Enter] key to start modify..."
if [[ -f "$(ls *.img 2>/dev/null)" ]]; then
	echo "Super Parttion Detect"
	superimg
elif [[ -f "$(ls *.zip 2>/dev/null)" ]]; then
	zipname=$(ls *.zip)
	echo "zip  detect"
	zipfile
else exit 0
fi
mkrw
mount
###############
debloat
vietsub
buildprop
read -p "Press [Enter] key to start modify..."
umount
shrink
remove_source
repackz