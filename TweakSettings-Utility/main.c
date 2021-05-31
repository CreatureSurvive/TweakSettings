#include <stdio.h>
#include <stdlib.h>
#include <sysexits.h>
#include <unistd.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/stat.h>

extern int reboot3(uint64_t arg);
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

int main(int argc, char **argv, char **envp) {

	// check that TweakSettings.app exists
	struct stat correct;
	if (lstat("/Applications/TweakSettings.app/TweakSettings", &correct) == -1){
		printf("tweaksettings-utility can only be used by TweakSettings.app,\n");
		return EX_NOPERM;
	}

	pid_t parent = getppid();
	bool tweaksettings = false;

	// check that TweakSettings.app is the parent process pid
	char buffer[(1024)] = {0};
	int pidpath = proc_pidpath(parent, buffer, sizeof(buffer));
	if (pidpath > 0){
		if (strcmp(buffer, "/Applications/TweakSettings.app/TweakSettings") == 0){
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
			execlp("/usr/bin/killall", "killall", "backboardd", NULL);
		} break;
		case TSUtilityActionTypeSafemode: {
			execlp("/usr/bin/killall", "killall", "-SEGV", "SpringBoard", NULL);
		} break;
		case TSUtilityActionTypeUICache: {
			execlp("/usr/bin/uicache", "uicache", NULL);
		} break;
		case TSUtilityActionTypeReboot: {
			execlp("/usr/bin/reboot", "reboot", NULL);
		} break;
		case TSUtilityActionTypeLDRestart: {
			execlp("/usr/bin/ldrestart", "ldrestart", NULL);
		} break;
		case TSUtilityActionTypeUSReboot: {
			status = reboot3(0x2000000000000000ULL);
		} break;
		case TSUtilityActionTypeTweakinject: {

			if (access("/usr/lib/TweakInject.dylib", F_OK) == 0) {

				if (access("/.disable_tweakinject", F_OK) == 0) {
					execlp("/bin/rm", "rm", "-f", "/.disable_tweakinject", NULL);
				} else {
					execlp("/bin/touch", "touch", "/.disable_tweakinject", NULL);
				}
			} else {
				if (access("/var/tmp/.substrated_disable_loader", F_OK) == 0) {
					execlp("/bin/rm", "rm", "-f", "/var/tmp/.substrated_disable_loader", NULL);
				} else {
					execlp("/bin/touch", "touch", "/var/tmp/.substrated_disable_loader", NULL);
				}
			}
		} break;
		case TSUtilityActionTypeSubstrated: {
			if (access("/etc/rc.d/substrate", F_OK) == 0) {
				execlp("/etc/rc.d/substrate", "substrate", NULL);
			}
		} break;
	}
	
	return status;
}
