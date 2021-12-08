#!/bin/bash
part=(system vendor product)
dir=$(pwd)
cd $dir
	if [[ -d "temp" ]]; then
		rm -r temp
		rm -r zip_temp
		rm -r img_temp
		rm -r module/vietsub_f
		rm -r module/fonts_f
		rm raw.img
	fi
for ((i = 0 ; i < 3 ; i++)); do
	if [[ -f "${part[$i]}.img" ]]; then
	rm -rf ${part[$i]}.img
	echo "dome"
	fi
done
