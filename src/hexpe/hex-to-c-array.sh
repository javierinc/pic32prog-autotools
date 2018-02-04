#!/bin/sh
# Small and horrible script to convert a intel hex file to
# a C array.
# Javier Pérez.

start_code=""
nbytes=""
address=""
rtype=""
data=""
cksum=""

function parse_line() {
    start_code=`echo $1 | cut -c1`

    nhexbytes=`echo $1 | cut -c2-3`
    nhexbytes="0x"$nhexbytes

    nbytes=`echo $(($nhexbytes))`
    address=`echo $1 | cut -c4-7`
    rtype=`echo $1 | cut -c8-9`

    if [ $nbytes -gt 0 ]; then
        data_end_pos=$(( 9 + $(($nbytes * 2)) ))
        data=`echo $1 | cut -c10-$data_end_pos`
        cksum=`echo $1 | cut -c$(($data_end_pos + 1))-$(($data_end_pos + 3))`
    else
        cksum=`echo $1 | cut -c10-13`
    fi

}

function invert() {
    i=$(( `echo -n $1 | wc -c ` - 1 ))

    out=""

    for ((; i>=1; i=i-2))
    do
        value=`echo $1 | cut -c$i-$(($i+1))`
        out=$out$value
    done

    echo $out
}

echo "const unsigned pic32_pexxx[] =  { "

global_address=0

while read -r line
do
    parse_line  "$line"

    if [ $rtype == "00" ] && [ $nbytes -gt 0 ]; then

        len=`echo -n $data | wc -c `
        printf "/*%04X*/" $global_address
        for ((i=0; i<len; i+=8))
        do
            value=`echo -n $data | cut -c$(($i + 1))-$(($i + 8))`
            value=`invert $value`
            printf " 0x%s," $value
            global_address=$(($global_address + 4))
        done
        printf "\n"
    fi
done < "$1"

## extra padding for PE. (see adapter-pickit2.c)
echo "0, 0, 0, 0, 0, 0, 0, 0, 0, 0, }; "

