package vbmc

import (
	"bufio"
	"bytes"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

type VbmcExecError struct {
	ExitCode int
	Stdout   string
	Stderr   string
}

func (err *VbmcExecError) Error() string {
	return fmt.Sprintf("failed to exec vbmc: exitCode=%d stdout=%s stderr=%s", err.ExitCode, err.Stdout, err.Stderr)
}

type Vbmc struct {
	DomainId string
	Port     int
}

func getContainerName(domainId string) string {
	return fmt.Sprintf("sushy-vbmc-emulator-%s", domainId)
}

func docker(args ...string) (string, error) {
	var stderr, stdout bytes.Buffer

	cmd := exec.Command("docker", args...)
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout

	err := cmd.Run()

	if err != nil {
		exitCode := -1
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ProcessState.ExitCode()
		}
		return "", &VbmcExecError{
			ExitCode: exitCode,
			Stdout:   stdout.String(),
			Stderr:   stderr.String(),
		}
	}

	return strings.TrimSpace(stdout.String()), nil
}

func Create(domainId string, address string, port int) (*Vbmc, error) {
	err := Delete(domainId)
	if err != nil {
		return nil, err
	}
	_, err = docker(
		"run",
		"--rm",
		"--name",
		getContainerName(domainId),
		"--detach",
		"-v",
		"/var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock",
		"-v",
		"/var/run/libvirt/libvirt-sock-ro:/var/run/libvirt/libvirt-sock-ro",
		"-e",
		fmt.Sprintf("SUSHY_EMULATOR_ALLOWED_INSTANCES=%s", domainId),
		"-p",
		fmt.Sprintf("%s:%d:8000", address, port),
		"ruilopes/sushy-vbmc-emulator")
	if err != nil {
		return nil, err
	}
	vbmc, err := Get(domainId)
	if err != nil {
		return nil, err
	}
	if vbmc == nil {
		return nil, fmt.Errorf("failed to create the vbmc container; it probably died for unknown reasons")
	}
	return vbmc, nil
}

func Delete(domainId string) error {
	containerName := getContainerName(domainId)
	_, err := docker("kill", "--signal", "INT", containerName)
	if err != nil {
		if execError, ok := err.(*VbmcExecError); ok {
			if strings.Contains(execError.Stderr, "No such container") {
				return nil
			}
		}
		return err
	}
	_, err = docker("wait", containerName)
	if err != nil {
		if execError, ok := err.(*VbmcExecError); ok {
			if strings.Contains(execError.Stderr, "No such container") {
				return nil
			}
		}
		return err
	}
	return nil
}

func Get(domainId string) (*Vbmc, error) {
	stdout, err := docker("port", getContainerName(domainId), "8000")
	if err != nil {
		if execError, ok := err.(*VbmcExecError); ok {
			if strings.Contains(execError.Stderr, "No such container") {
				return nil, nil
			}
		}
		return nil, err
	}

	vbmc := &Vbmc{
		DomainId: domainId,
	}

	scanner := bufio.NewScanner(strings.NewReader(stdout))
	for scanner.Scan() {
		// e.g. 0.0.0.0:8000
		line := scanner.Text()
		parts := strings.SplitN(line, ":", -1)
		if len(parts) < 1 {
			continue
		}
		port, err := strconv.Atoi(parts[len(parts)-1])
		if err != nil {
			return nil, err
		}
		vbmc.Port = port
	}

	err = scanner.Err()
	if err != nil {
		return nil, err
	}

	return vbmc, nil
}
