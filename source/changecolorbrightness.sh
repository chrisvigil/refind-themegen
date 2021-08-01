#!/bin/bash
#################################################
# changecolorbrightness.sh 
# 
# Takes a rgb color as a hex value (ie f0f0f0) and returns a 
# color in the same format that is a specified precent darker
# or with a specified HSV value.
#
# ARGS: $1 (required): The rgb color to convert as a hex value
#		$2 (required): For values less the 1, the percentage 
#			of the inputs colors brightness value that the 
#			returned color will have expressed as a decimal 
#			value between 0 and 1 (ie 0.65). 
#			For values 1 or larger the exact HSV value attribute
#			used instead of a percentage of the input color's
#			
# OUTS: A rgb color to stdout as hex value
# NOTE: requires the bc command
#################################################


# DESC: Returns the largest of 3 values
# ARGS: $1 (required): A integer or decimal value
#		$2 (required): A integer or decimal value
#		$3 (required): A integer or decimal value
# OUTS: The largest of the 3 argument values
get_max() {
		if [[ $(bc<<<"$1 < $2") = 1 ]]; then
				if [[ $(bc<<<"$2 < $3") = 1 ]]; then
                    echo $3
            else    
                    echo $2
            fi
        else
				if [[ $(bc<<<"$1 < $3") = 1 ]]; then
                    echo $3
            else    
                    echo $1
            fi
        fi
}

# DESC: Returns the smallest of 3 values
# ARGS: $1 (required): A integer or decimal value
#		$2 (required): A integer or decimal value
#		$3 (required): A integer or decimal value
# OUTS: The smallest of the 3 argument values
get_min() {
		if [[ $(bc<<<"$1 > $2") = 1 ]]; then
				if [[ $(bc<<<"$2 > $3") = 1 ]]; then
						echo $3
	            else    
						echo $2
		        fi
        else
				if [[ $(bc<<<"$1 > $3") = 1 ]]; then
					    echo $3
			    else    
					    echo $1
				fi
        fi
}

# DESC: Takes a RGB color as a hex value and returns a 
#		corresponding HSV value color.
# ARGS: $1 (required): A rgb color as a hex value (ie 'f0f0f0')
# OUTS: A color as an HSV value, each value rounded to 4 decimals
#		(ie. '0.1234,0.1234,0.1234')
# NOTE: adapted from https://gist.github.com/mjackson/5311256 
rgb_to_hsv() {
		local r=$(echo $(printf "%d\n" 0x${1:0:2})/255 | bc -l)
		local g=$(echo $(printf "%d\n" 0x${1:2:2})/255 | bc -l)
		local b=$(echo $(printf "%d\n" 0x${1:4:2})/255 | bc -l)
		
		local max=$(get_max $r $g $b)

		local min=$(get_min $r $g $b)

        local v=$max
		local d=$(echo $max-$min | bc -l)

        local s=0

		if [[ $(bc<<<"$max != 0") = 1 ]]; then
				local s=$(echo $d/$max | bc -l)
        fi

        local h=0
		if [[ $(bc<<<"$max != $min") = 1 ]]; then
                case $max in
                        $r)
                                local temp=0
								if [[ $(bc<<<"$g < $b") = 1 ]]; then
                                        temp=6
                                fi
								h=$(echo "($g-$b)/$d+$temp" | bc -l)
                                ;;
                        $g)
								h=$(echo "($b-$r)/$d+2" | bc -l)
                                ;;
                        $b)
								h=$(echo "($r-$g)/$d+4" | bc -l)
                                ;;
                esac
				h=$(echo $h/6 | bc -l)
        fi
		h=$(printf "%.4f" $h)
		s=$(printf "%.4f" $s)
		v=$(printf "%.4f" $v)
		echo $h,$s,$v
}

# DESC: Takes a HSV color and returns a corresponding RGB value color.
# ARGS: $1 (required): A color as an HSV value, each value rounded to 
#		4 decimals (ie. '0.1234,0.1234,0.1234')
# OUTS: A rgb color as a hex value (ie 'f0f0f0')
# NOTE: adapted from https://gist.github.com/mjackson/5311256 
hsv_to_rgb(){
		local h=${1:0:6}
		local s=${1:7:6}
		local v=${1:14:6}
	
		#scale only works when dividing so we divide by 1
		#bc does not round up so is equivalent to floor(h * 6)
		local i=$(echo "scale=0;($h*6)/1" | bc)
		
		local f=$(echo "$h*6-$i" | bc)
		local p=$(echo "$v*(1-$s)" | bc)
		local q=$(echo "$v*(1-$f*$s)" | bc)
		local t=$(echo "$v*(1-(1-$f)*$s)" | bc)	

		case $(bc<<<$i%6) in
				0)
						local r=$v
						local g=$t
						local b=$p
						;;
				1)
						local r=$q
						local g=$v
						local b=$p
						;;
				2)
						local r=$p
						local g=$v
						local b=$t
						;;
				3)
						local r=$p
						local g=$q
						local b=$v
						;;
				4)
						local r=$t
						local g=$p
						local b=$v
						;;
				5)
						local r=$v
						local g=$p
						local b=$q
						;;
		esac

		r=$(printf "%.0f" $(bc<<<$r*255))
		g=$(printf "%.0f" $(bc<<<$g*255))
		b=$(printf "%.0f" $(bc<<<$b*255))
		
		#convert to hex
		r=$(printf '%x' $r)
		g=$(printf '%x' $g)
		b=$(printf '%x' $b)
		echo $r$g$b
}

# Convert $1 to HSV
hsv=$(rgb_to_hsv $1)

# Extracts the hue and saturation attributes
new_hs=${hsv:0:14}

# If $2 is less then 1 set the HSV value attribute to 
# a percentage of the input colors value attribute.
# If $2 is 1 or larger uses $2 as the new value attribute
# (expressed as a decimal
if [[ $(bc<<<"$2 < 1") = 1 ]]; then	
		new_v=$(bc<<<${hsv:14:6}*$2)
else
		new_v=$(bc<<<"$2 * 0.01")
fi

# Concatenates the hue and saturation with the new value
new_v=$(printf "%.4f" $new_v)
new_hsv=$new_hs$new_v

# Converts the HSV back to hex RGB and prints to stdout
echo $(hsv_to_rgb $new_hsv)
