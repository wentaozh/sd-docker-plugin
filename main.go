package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	dkvolume "github.com/docker/go-plugins-helpers/volume"
)

var (
	pluginName	 = flag.String("name", "sheepdog", "Docker plugin name for use on --volume-driver option")
	sdUser		 = flag.String("user", "admin", "sheepdog User")
	sdAddr		 = flag.String("addr", "127.0.0.1", "sheepdog gateway default ip addr")
	sdPort		 = flag.Int("port", 7000, "sheepdog gateway default port")
	pluginDir	 = flag.String("plugins", "/run/docker/plugins", "Docker plugin directory for socket")
	rootMountDir	 = flag.String("mount", dkvolume.DefaultDockerRootDirectory, "Mount directory for volumes on host")
	logDir		 = flag.String("logdir", "/var/log", "Logfile directory")
	canCreateVolumes = flag.Bool("create", false, "Can auto Create sheepdog Images")
	canRemoveVolumes = flag.Bool("remove", false, "Can Remove (destroy) sheepdog Images")
	defaultImageSizeMB = flag.Int("size", 20*1024, "sheepdog Image size to Create (in MB) (default: 20480=20GB)")
	defaultImageFSType = flag.String("fs", "xfs", "FS type for the created sheepdog Image (must have mkfs.type)")
)

func init() {
	flag.Parse()
}

func socketPath() string {
	return filepath.Join(*pluginDir, *pluginName+".sock")
}

func logfilePath() string {
	return filepath.Join(*logDir, *pluginName+"-docker-plugin.log")
}

func main() {
	logFile, err := setupLogging()
	if err != nil {
		log.Panicf{"Unable to setup logging: %s", err}
	}
	defer shutdownLogging(logFile)

	log.Printf(
		"INFO: Setting up sheepdog driver for PluginID=%s, user=%s, mount=%s",
		*pluginName,
		*sdUser,
		*rootMountDir
	)

	d := newSheepdogVolumeDriver(
		*pluginName,
		*sdUser,
		*sdAddr,
		*sdPort,
		*rootMountDir,
	)

	defer d.shutdown()

	log.Printf("INFO: Creating Docker VolumeDriver Handler")
	h := dkvolume.NewHandler(d)

	socket := socketPath()
}
