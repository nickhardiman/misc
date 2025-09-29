#!/bin/bash
# was part of https://github.com/redhat-cop/infra.lvm_snapshots/tree/main/roles/shrink_lv/

am_i_root() {
    MY_ID=$(id -u)
    [[ "$VERBOSE" -eq 0 ]] && echo "I am UID $MY_ID"
    if [ "$MY_ID" -ne 0 ]; then
        echo "$0 error:  You must be root to use LVS"
        exit 8
    fi
}

usage() {
    echo "Usage: $0 [-h|-v] PV"
    echo "Clear space at the end of an LVM logical volume"
    echo "Options:"
    echo "  -h  Show this help message"
    echo "  -v  Verbose output"
    echo "  -t  Test, do not change anything, just show what would be done"
    echo "Exit codes:"
    echo "  0  Success"
    echo "  1  Usage"
    echo "  2  No PV information found"
    echo "  3  No free space found"
    echo "  4  Problem finding last linear extent"
    echo "  5  Problem moving extents"
    echo "  6  Bad command line arguments"
    echo "  7  PV is not a block device"
    echo "  8  Not run as root"
    exit 1
}

# Show current segment map
show_pv_segments() {
    echo 'all PV segments:'
    pvs "$PVDEV" --segments -o lvname,pvseg_start,pvseg_size,seg_le_ranges,segtype
    if [ $? -ne 0 ]; then
        echo "$0 error:   Problem getting PV segment information"
        exit 2
    fi
}

# Set variables LVM2_PVSEG_START and LVM2_PVSEG_SIZE using the pvs command. 
find_first_free_segment() {
    pvsargs="--noheadings --nameprefixes --segments -o pvseg_start,pvseg_size,segtype"
    LVM2_PVSEG_START=
    eval $(pvs "$PVDEV" $pvsargs | grep SEGTYPE=.free. | head -n1)
    if [ -z "$LVM2_PVSEG_START" ]; then
        echo "$0 error:  No free segments found on $PVDEV"
        exit 3
    fi
    free_start=$LVM2_PVSEG_START
    free_size=$LVM2_PVSEG_SIZE
    [[ "$VERBOSE" -eq 0 ]] && echo 'first free PV segment'
    [[ "$VERBOSE" -eq 0 ]] && echo "  Type Start SSize"
    [[ "$VERBOSE" -eq 0 ]] && echo "  free $free_start $free_size"
}

find_last_linear_segment() {
    pvsargs="--noheadings --nameprefixes --segments -o pvseg_start,pvseg_size,segtype"
    LVM2_PVSEG_START=
    eval $(pvs "$PVDEV" $pvsargs | grep SEGTYPE=.linear. | tail -n1)
    if [ -z "$LVM2_PVSEG_START" ]; then
        echo "$0 error:  No linear extents found on $PVDEV"
        exit 4
    fi
    last_pv_start=$LVM2_PVSEG_START
    last_pv_size=$LVM2_PVSEG_SIZE
    [[ "$VERBOSE" -eq 0 ]] && echo 'last linear PV segment'
    [[ "$VERBOSE" -eq 0 ]] && echo "  Type Start SSize"
    [[ "$VERBOSE" -eq 0 ]] && echo "  linear $last_start $last_size"
}

all_free_space_at_end() {
    if [[ $free_start -gt $last_pv_start ]]
    then
        [[ "$VERBOSE" -eq 0 ]] && echo 'all free space is after linear PEs'
        /usr/bin/true
    else
        [[ "$VERBOSE" -eq 0 ]] && echo 'some free space is not after linear PEs'
        /usr/bin/false
    fi
}

pick_range_to_move() {
    if [[ $free_size -gt $last_pv_size ]]
    then
        free_size=$last_pv_size
    fi
    from_range="PVDEV:$((last_pv_start+last_pv_size-free_size))-$((last_pv_start+last_pv_size-1))"
    to_range="PVDEV:$free_start-$((free_start+free_size-1))
    [[ "$VERBOSE" -eq 0 ]] && echo "moving $free_size PEs from $from_range to $to_range..."
} 

move_extents() {
    MOVE_COMMAND="pvmove --atomic --alloc anywhere $from_range $to_range"
    [[ "$VERBOSE" -eq 0 ]] && echo "  command: $MOVE_COMMAND"
    [[ "$TEST" -eq 1 ]] && $MOVE_COMMAND"
    if [ $? -ne 0 ]; then
        echo "$0 error:  Problem moving extents"
        exit 5
    fi
}

read_cli_options() {
    while getopts ":hvt" option; do
        case $option in
            h) # display help
                usage
                ;;
            v) # verbose output
                VERBOSE=0
                ;;
            t) # test only, do not change anything
                VERBOSE=0
                TEST=0
                ;;
            \?) # Invalid option
                echo "$0 error:   Invalid option: -$OPTARG" >&2
                exit 6
                ;;
        esac
    done
}

read_cli_device() {
    shift $((OPTIND-1))
    if [ $# -ne 1 ]; then
        echo "$0 error:   You must specify exactly one PV device" >&2
        usage
    fi
    PVDEV=$1
    if [ ! -b "$PVDEV" ]; then
        echo "$0 error:  $PVDEV is not a block device" >&2
        exit 7
    fi
}

#---------
# Main script starts here

# Set defaults
# 0 is true, 1 is false
VERBOSE=1   # 0=noisy, 1=quiet
TEST=1      # 0=safe, 1=dangerous
MOVE_COUNT=0

# Process command line options
read_cli_options "$@"
read_cli_device "$@"
am_i_root
[[ "$VERBOSE" -eq 0 ]] && echo "before pvsqueeze"
[[ "$VERBOSE" -eq 0 ]] && show_pv_segments

# iterate until all free space is at the end of the PV
while true; do
    find_first_free_segment
    find_last_linear_segment
    if all_free_space_at_end; then
        break
    fi
    pick_range_to_move
    move_extents
    MOVE_COUNT=$((MOVE_COUNT+1))
done

if [[ "$VERBOSE" -eq 0 ]]
then
    echo
    echo "after pvsqueeze"
    show_pv_segments
else
    echo done
fi
exit 0
#---------
# End of script
