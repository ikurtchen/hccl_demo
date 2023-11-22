#/bin/bash
#set -ex

hostname=`hostname`
hostid=${hostname##*-}
hostid=${hostid//[^0-9]/}
hostid=${hostid##0}

if [ -z ${hostid} ]; then
    echo "can't decide hostid from hostname: ${hostname}"
    exit 1
fi

ibds=(mlx5_0 mlx5_1 mlx5_2 mlx5_3 mlx5_4 mlx5_5 mlx5_6 mlx5_7)

id=1

for ibd in ${ibds[@]}; do
    ibrsc=$(cat /sys/class/infiniband/$ibd/device/resource)

    eths=$(ls /sys/class/net/)
    for eth in $eths; do
        filepath_resource=/sys/class/net/$eth/device/resource
        if [ -f $filepath_resource ]; then
            ethrsc=$(cat $filepath_resource)
            if [ "x$ethrsc" == "x$ibrsc" ]; then
                                echo "ifconfig $eth 255.255.255.0 192.168.$id.$hostid"
                ifconfig $eth 255.255.255.0 192.168.$id.$hostid
                                break
            fi
        fi
    done
    id=$(( $id+1 ))
done

