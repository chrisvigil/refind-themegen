#!/bin/bash
############################################################
# createtheme.sh
# 
# Generates a refind theme.
#
# Requires bc, imagemagick and librsvg
############################################################


### CONFIG ###


# Set theme name
themename=refind-forrest

# Path to source files
source=./source

##  Refind theme.conf option, should be reviewed after generation ##
hidebadges=false
hideinternalbadge=true
hidelabel=false
# also determines size of the background.png, if "0 0"
# is used then 1920x1080 will be used for background.png
# generation but refind will use the system default resolution
resolution="0 0"
showtools=true
showshutdown=true
showreboot=true
showfirmware=true
showshell=false #icon not implemented yet

## icon and background generation options ##
recoloricons=true

# Set icon colors (do not change old colors unless the icon svgs have been changed)
# newbasecolor is the main icon color
# newdarkcolor is the secondary color used for icons, is generated from newbasecolor
# by default.
oldbasecolor=ecf0f1
olddarkcolor=898989
newbasecolor=5d8147
newdarkcolor=$($source/changecolorbrightness.sh $newbasecolor 0.65)

# If set to false will use default grayscale background
colorbg=true

# Sets the base color for the background, If variable is not set a color will
# be generated based on the icon base color
# bgcolor=$newbasecolor


### THEME GENERATION ###

# Creates theme folders
printf "Creating theme folder..."
mkdir $themename
mkdir $themename/icons
printf "done\n"

# Copies files to theme directory
printf "Copying source files..."
cp $source/*.svg $themename/
cp $source/theme.conf $themename/theme.conf
printf "done\n"

# Setup conf file
printf "Setting up config file..."
sed -i 's/THEMENAME/'$themename'/g' $themename/theme.conf

uiline="singleuser,hints,arrows"
if [ "$hidebadges" == true ]; then
		uiline="${uiline},badges"
fi

if [ "$hidelabel" == true ]; then
		uiline="${uiline},label"
fi

sed -i 's/#hideui/hideui '$uiline'/' $themename/theme.conf

if [ "$resolution" != "0 0" ]; then
		sed -i "s/#resolution 0 0/resolution $resolution/" $themename/theme.conf
fi


tools=showtools
if [ "$showshutdown" == true ]; then
		tools="${tools},shutdown"
fi

if [ "$showreboot" == true ]; then
		tools="${tools},reboot"
fi


if [ "$showfirmware" == true ]; then
		tools="${tools},firmware"
fi


if [ "$showshell" == true ]; then
		tools="${tools},shell"
fi

tools=${tools/,/ }

sed -i "s/#showtools/$tools/" $themename/theme.conf
printf "done\n"


# Recolor icons
if [[ $recoloricons == true ]]; then
		printf "Recoloring icons..."
		sed -i "s/fill:#$oldbasecolor/fill:#$newbasecolor/g" $themename/*.svg
		sed -i "s/fill:#$olddarkcolor/fill:#$newdarkcolor/g" $themename/*.svg
		sed -i "s/stroke:#$oldbasecolor/stroke:#$newbasecolor/g" $themename/*.svg
		sed -i "s/stroke:#$olddarkcolor/stroke:#$newdarkcolor/g" $themename/*.svg
		printf "done\n"
fi

# $1 = file name with relative path, $2 = themename, $3 = size 
svgpath_to_png() {
		local filename=${1%.svg}
		local filename=${filename#$2/}
		magick convert -background none -resize $3 $1 $2/icons/$filename.png
}

# Convert icons to png
printf "Converting svgs to pngs..."
for file in $themename/os_*.svg; do
	svgpath_to_png $file $themename '128x128'
done;



for file in $themename/func_*.svg; do	
	svgpath_to_png $file $themename '48x48'
done;

if [[ $hidebadges != true ]]; then
	for file in $themename/vol_*.svg; do
		svgpath_to_png $file $themename '32x32'
	done;

	if [[ $hideinternalbadge == true ]]; then
			rm $themename/icons/vol_internal.png
			cp $source/vol_internal_alt.png $themename/icons/vol_internal.png
	fi	
fi

#for file in $themename/tool_*.svg; do
#	svgpath_to_png $file $themename '48x48'	
#done;

svgpath_to_png $themename/mouse.svg $themename '120x120'


svgpath_to_png $themename/selection_big.svg $themename '144x144'

svgpath_to_png $themename/selection_small.svg $themename '64x64'

mv $themename/icons/selection* $themename/
printf "done\n"

# Generate background
printf "Creating background..."
if [[ "$resolution" == "0 0" ]]; then
		bgsize=1920x1080
else
		bgsize=$(echo $resolution | awk '{print $1}')x
		bgsize=$bgsize$(echo $resolution | awk '{print $2}')
fi

if [[ $colorbg == true ]]; then
		if [ -z ${bgcolor+x} ]; then
				bgcolor=$($source/changecolorbrightness.sh $newbasecolor 50)
		fi
		magick convert $source/background_original.png \( +clone +matte -fill "#$bgcolor" -colorize 100% \) -compose Hardlight -composite -resize $bgsize\! $themename/background.png
else
		magick convert $source/background_original.png -resize 1920x1080\! $themename/background.png
fi
printf "done\n"

# Removes unneeded files
printf "Removing unneeded files..."
rm $themename/*.svg
printf "done \n"
