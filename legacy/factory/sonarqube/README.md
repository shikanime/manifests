# SonarQube

SonarQube is the leading tool for continuously inspecting the Code Quality and
Security of your codebases, and guiding development teams during Code Reviews.
Covering 27 programming languages, while pairing-up with your existing software
pipeline, SonarQube provides clear remediation guidance for developers to
understand and fix issues, and for teams overall to deliver better and safer
software. With over 225,000 deployments helping small development teams as well
as global organizations, SonarQube provides the means for all teams and
companies around the world to own and impact their Code Quality and Security.

## Known Issues

### Linux

If you're running on Linux, you must ensure that:

- vm.max_map_count is greater than or equal to 524288
- fs.file-max is greater than or equal to 131072
- the user running SonarQube can open at least 131072 file descriptors
- the user running SonarQube can open at least 8192 threads

You can see the values with the following commands:

```shell
sysctl vm.max_map_count
sysctl fs.file-max
ulimit -n
ulimit -u
```

You can set them dynamically for the current session by running the following
commands as root:

```shell
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
```
