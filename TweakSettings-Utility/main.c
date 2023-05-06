#include <stdio.h>
#include <stdlib.h>
#include <sysexits.h>
#include <unistd.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/stat.h>

#import "rootless.h"
#include <errno.h>

int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);

typedef enum {
	TSUtilityActionTypeNone,
	TSUtilityActionTypeHelp,
	TSUtilityActionTypeRespring,
	TSUtilityActionTypeSafemode,
	TSUtilityActionTypeUICache,
	TSUtilityActionTypeLDRestart,
	TSUtilityActionTypeReboot,
	TSUtilityActionTypeUSReboot,
	TSUtilityActionTypeTweakinject,
	TSUtilityActionTypeSubstrated
} TSUtilityActionType;

// patch setuid for electra based jailbreaks
void patch_setuid(uid_t user) {
	
	void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
	if (!handle) { return; }

	typedef void (*fix_setuid_prt_t)(__attribute__((unused)) pid_t pid);
	typedef void (*fix_entitle_prt_t)(__attribute__((unused)) pid_t pid, __attribute__((unused)) uint32_t what);
	fix_setuid_prt_t setuidptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
	fix_entitle_prt_t entitleptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");

	setuidptr(getpid());
	setuid(user);

	if (dlerror()) { return; }

	entitleptr(getpid(), (1 << 1));
}

// prints help text
void print_usage() {
	printf("tweaksettings-utility usage:\n\n");
	printf("[--respring]:\n\trespring the device\n");
	printf("[--safemode]:\n\tenter safemode on the device\n");
	printf("[--uicache]:\n\trun uicache on the device\n");
	printf("[--ldrestart]:\n\trun ldrestart on the device\n");
	printf("[--reboot]:\n\treboot the device\n");
	printf("[--usreboot]:\n\tuserspace reboot the device\n");
	printf("[--tweakinject]:\n\ttoggle tweakinject on the device (libhooker only)\n");
	printf("[--help]:\n\tshows this help text\n\n");
	printf("tweaksettings-utility is for use only by TweakSettings\n\n");
}

int status_for_cmd(const char *cmd) {
    FILE *proc = popen(cmd, "r");

    if (!proc) {return EXIT_FAILURE;}

    int size = 1024;
    char data[size];
    while (fgets(data, size, proc) != NULL) {}

    return pclose(proc);
}

int check_fork(pid_t pid) {
    if (pid != 0) {
        printf("tweaksettings-utility fork error (%s) (%d),\n", strerror(errno), errno);
    }

    return pid;
}

int wait_pid(pid_t pid) {
    int wait;
    int status;
    if ((wait = waitpid (pid, &status, 0)) == -1)
        printf("tweaksettings-utility wait error (%s) (%d),\n", strerror(errno), errno);
    if (wait == pid) {
        return 0;
    }
    return -1;
}

int main(int argc, char **argv, char **envp) {

	// check that TweakSettings.app exists
	struct stat correct;
	if (lstat(ROOT_PATH("/Applications/TweakSettings.app/TweakSettings"), &correct) == -1){
		printf("tweaksettings-utility can only be used by TweakSettings.app,\n");
		return EX_NOPERM;
	}

	pid_t parent = getppid();
	bool tweaksettings = false;

	// check that TweakSettings.app is the parent process pid
	char buffer[(1024)] = {0};
	int pidpath = proc_pidpath(parent, buffer, sizeof(buffer));
	if (pidpath > 0){
		if (strcmp(buffer, ROOT_PATH("/Applications/TweakSettings.app/TweakSettings")) == 0){
			tweaksettings = true;
		}
	}

	// exit if the parent process was not TweakSettings.app
	if (tweaksettings == false){
		printf("tweaksettings-utility can only be used by TweakSettings.app,\n");
		return EX_NOPERM;
	}
	
	// patch setuid if needed
	patch_setuid(0);

	// get root:wheel 
	setuid(0);
	setgid(0);

	// some permissions issue prevented getting root:wheel
	// exit the program with a permissions error
	if (getuid() != 0 || getgid() != 0) {
		printf("the more you get,\n");
		printf("the less you are.\n");
		return EX_NOPERM;
	}

	// show help text if no arguments were supplied
	if (argc < 2) {
		print_usage();
		return EX_OK;
	}

	// parse cmd args and set the operation flags
	TSUtilityActionType flags =
			strcmp(argv[1], "--respring") == 0 ? TSUtilityActionTypeRespring :
			strcmp(argv[1], "--safemode") == 0 ? TSUtilityActionTypeSafemode :
			strcmp(argv[1], "--uicache") == 0 ? TSUtilityActionTypeUICache :
			strcmp(argv[1], "--ldrestart") == 0 ? TSUtilityActionTypeLDRestart :
			strcmp(argv[1], "--reboot") == 0 ? TSUtilityActionTypeReboot :
			strcmp(argv[1], "--usreboot") == 0 ? TSUtilityActionTypeUSReboot :
			strcmp(argv[1], "--tweakinject") == 0 ? TSUtilityActionTypeTweakinject :
			strcmp(argv[1], "--substrated") == 0 ? TSUtilityActionTypeSubstrated :
			strcmp(argv[1], "--help") == 0 ? TSUtilityActionTypeHelp :
			TSUtilityActionTypeNone;

	int status = EX_UNAVAILABLE;

	// handle operation execution
	switch (flags) {
		case TSUtilityActionTypeNone: {
			printf("invalid arguments, canceling operation\n");
		} break;
		case TSUtilityActionTypeHelp: {
			print_usage();
		} break;
		case TSUtilityActionTypeRespring: {
            status = execl(ROOT_PATH("/usr/bin/killall"), "killall", "backboardd", NULL);
		} break;
		case TSUtilityActionTypeSafemode: {
		    status = execl(ROOT_PATH("/usr/bin/killall"), "killall", "-SEGV", "SpringBoard", NULL);
		} break;
		case TSUtilityActionTypeUICache: {
		    status = execl(ROOT_PATH("/usr/bin/uicache"), "uicache", NULL);
		} break;
		case TSUtilityActionTypeReboot: {
		    status = execl(ROOT_PATH("/usr/sbin/reboot"), "reboot", NULL);
		} break;
		case TSUtilityActionTypeLDRestart: {
		    status = execl(ROOT_PATH("/usr/bin/ldrestart"), "ldrestart", NULL);
		} break;
		case TSUtilityActionTypeUSReboot: {
            status = execl(ROOT_PATH("/usr/bin/launchctl"), "launchctl", "reboot", "userspace", NULL);
		} break;
		case TSUtilityActionTypeTweakinject: {
            if (access("/var/jb/.installed_dopamine", F_OK) == 0) {
                pid_t cpid = fork();
                if (cpid == 0) {
                    status = access("/var/jb/basebin/.safe_mode", F_OK) == 0
                            ? execl(ROOT_PATH("/bin/rm"), "rm", "-f", "/var/jb/basebin/.safe_mode", NULL)
                            : execl(ROOT_PATH("/bin/touch"), "touch", "/var/jb/basebin/.safe_mode", NULL);
                }

                if (wait_pid(cpid) == 0) {
                    status = execl(ROOT_PATH("/usr/bin/launchctl"), "launchctl", "reboot", "userspace", NULL);
                }
            } else if (access(ROOT_PATH("/usr/lib/TweakInject.dylib"), F_OK) == 0) {
                pid_t cpid = fork();

                if (cpid == 0) {
                    status = access(ROOT_PATH("/.disable_tweakinject"), F_OK) == 0
                            ? execl(ROOT_PATH("/bin/rm"), "rm", "-f", ROOT_PATH("/.disable_tweakinject"), NULL)
                            : execl(ROOT_PATH("/bin/touch"), "touch", ROOT_PATH("/.disable_tweakinject"), NULL);
                }

                if (wait_pid(cpid) == 0) {
                    status = execl(ROOT_PATH("/usr/bin/killall"), "killall", "backboardd", NULL);
                }
			} else {
                pid_t cpid = fork();

                if (cpid == 0) {
                    status = access(ROOT_PATH("/var/tmp/.substrated_disable_loader"), F_OK) == 0
                            ? execl(ROOT_PATH("/bin/rm"), "rm", "-f", ROOT_PATH("/var/tmp/.substrated_disable_loader"), NULL)
                            : execl(ROOT_PATH("/bin/touch"), "touch", ROOT_PATH("/var/tmp/.substrated_disable_loader"), NULL);
                }

                if (wait_pid(cpid) == 0) {
                    cpid = fork();

                    if (cpid == 0) {
                        status = execl(ROOT_PATH("/etc/rc.d/substrate"), "substrate", NULL);
                    }

                    if (wait_pid(cpid) == 0) {
                        status = execl(ROOT_PATH("/usr/bin/killall"), "killall", "backboardd", NULL);
                    }
                }
			}
		} break;
		case TSUtilityActionTypeSubstrated: {
			if (access("/etc/rc.d/substrate", F_OK) == 0) {
				execl("/etc/rc.d/substrate", "substrate", NULL);
			}
		} break;
	}
	
	return status;
}
