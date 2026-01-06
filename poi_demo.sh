#!/bin/bash

# set environment parameters here
export GZ_VERSION=harmonic

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PX4_HOME=$SCRIPT_DIR
LAUNCH_QGC=true
GZ_WORLD=poi_demo_world_traffic
SIM_SPEED_FACTOR=0.7
HOME_LAT=32.0617
HOME_LON=118.778
DEBUG_GZ=false

# --------------------------------------------------------------------------
# Define drones: launch_gz name autostart  model   pose(x,y,z)     udp_port   instance
# --------------------------------------------------------------------------
DRONES=(
    "1 Drone1 4001 x500_gimbal              10.3,10.5,0.68       14540 0"
)

# check to see if Gazebo is already running
if ps -ef | grep 'gz' | grep 'sim' > /dev/null 2>&1; then
    echo "It looks like Gazebo is already running. Double check processes?"
    procs=$(ps -ef | grep 'gz' | grep 'sim')
    echo "$procs"
    ps_id=$(awk '{print $2}' <<< "$procs")
    echo "Consider: kill -9 ${ps_id}"

    exit 1
fi

# Launch QGroundControl if desired
if [[ "${LAUNCH_QGC}" == "true" ]] && [[ "${DEBUG_GZ}" == "false" ]]; then
    echo "Launching QGroundControl"
    gnome-terminal --tab --title="QGroundControl" -- bash -c "~/qgc/QGroundControl-x86_64-stable_5.0.8.AppImage; bash"
    sleep 7
fi

# Launch each drone
for drone in "${DRONES[@]}"; do
    # Parse each line into variables
    read -r LAUNCH_GZ NAME AUTOSTART MODEL POSE PORT INSTANCE <<< "$drone"

    echo "Launching $NAME..."

    if [[ "${LAUNCH_GZ}" == "1" ]]; then
        # do we need $INSTANCE here?

        # TODO: move startup script to drone specific location in table above
        PX4_LAUNCH_CMD="
            make px4_sitl \
            gz_${MODEL} \
            PX4_HOME_LAT=${HOME_LAT} \
            PX4_HOME_LON=${HOME_LON} \
            PX4_HOME_ALT=0 \
            PX4_GZ_WORLD=${GZ_WORLD} \
            PX4_SYS_AUTOSTART=$AUTOSTART \
            PX4_GZ_MODEL_POSE=\"$POSE\";"
    else
        # do we need PX4_MAV_UDP_PORT=$PORT \ ?
        PX4_LAUNCH_CMD="
            PX4_HOME_LAT=${HOME_LAT} \
            PX4_HOME_LON=${HOME_LON} \
            PX4_HOME_ALT=0 \
            PX4_GZ_WORLD=${GZ_WORLD} \
            PX4_SYS_AUTOSTART=$AUTOSTART \
            PX4_SIM_MODEL=$MODEL \
            PX4_GZ_MODEL_POSE=\"$POSE\" \
            ./build/px4_sitl_default/bin/px4 -i $INSTANCE;"
    fi


    LAUNCH_CMD="gnome-terminal --tab --title=\"$NAME\" -- bash -c '

        echo -ne \"\033]0;PX4 for ${NAME}\007\"; \
        cd ${PX4_HOME}; \

        rm -f ${PX4_HOME}/build/px4_sitl_default/instance_* /dataman;

        export PX4_GZ_MODELS=${PX4_HOME}/Tools/simulation/gz/models;
        export PX4_GZ_MODELS=${PX4_HOME}/Tools/simulation/gz/models;
        export PX4_GZ_WORLDS=${PX4_HOME}/Tools/simulation/gz/worlds;
        export PX4_GZ_PLUGINS=${PX4_HOME}/build/px4_sitl_default/src/modules/simulation/gz_plugins;
        export PX4_GZ_SERVER_CONFIG=${PX4_HOME}/src/modules/simulation/gz_bridge/server.config
        export GZ_SIM_RESOURCE_PATH=\${GZ_SIM_RESOURCE_PATH}:\${PX4_GZ_MODELS}:\${PX4_GZ_WORLDS};
        export GZ_SIM_SYSTEM_PLUGIN_PATH=\$GZ_SIM_SYSTEM_PLUGIN_PATH:\$PX4_GZ_PLUGINS;
        export GZ_SIM_SERVER_CONFIG_PATH=\$PX4_GZ_SERVER_CONFIG;

        export PX4_SIM_SPEED_FACTOR=${SIM_SPEED_FACTOR};

        ${PX4_LAUNCH_CMD}

        sleep 3;
        exec bash;
    '"

    eval ${LAUNCH_CMD}

    # important! So that subsequent drones connect to the existing gazebo, we have to give that process time to spin up
    if [[ "${LAUNCH_GZ}" == "1" ]]; then
        sleep 5
    fi


# bridge gazebo camera topic to ROS2
if [[ "${DEBUG_GZ}" == "false" ]]; then
    # wait for Gazebo to start so that the camera is publishing data
    sleep 10
    echo "Bridging Camera output to ROS"
    gnome-terminal --tab --title="ROS Bridge" -- bash -c "ros2 run ros_gz_bridge parameter_bridge /world/poi_demo_world_traffic/model/x500_gimbal_0/link/camera_link/sensor/camera/image@sensor_msgs/msg/Image@gz.msgs.Image; bash"
fi

# optionally view the camera output using rqt_image_view
#echo "Viewing Camera output"
#gnome-terminal --tab --title="RQT Image Viewer" -- bash -c "ros2 run rqt_image_view rqt_image_view /world/poi_demo_world_traffic/model/x500_gimbal_0/link/camera_link/sensor/camera/image; bash

done
