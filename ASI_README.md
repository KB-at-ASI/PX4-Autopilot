# Instructions for running PX4 Swarm demo for AirSpace Innovation

1. Clone repository:

```
git clone --recurse-submodules git@github.com:KB-at-ASI/PX4-Autopilot.git
```


2. Build PX4

```
make px4_sitl
```


3. Run demo

```
chmod u+x swarm.sh
./swarm.sh
```

# Known Issues

- Launching QGroundControl, several warning messages display about firmware version errors. These seem ok to dismiss.
