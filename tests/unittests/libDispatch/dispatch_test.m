//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// Copyright (c) 2008-2009 Apple Inc. All rights reserved.
//
// @APPLE_APACHE_LICENSE_HEADER_START@
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// @APPLE_APACHE_LICENSE_HEADER_END@
//
//******************************************************************************

#include <TestFramework.h>
#include "dispatch_test.h"

#include <sys/types.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include <errno.h>

#include <string.h>
#import <Foundation/Foundation.h>
#import <NSThread-Internal.h>
#import <NSRunLoop+Internal.h>

static int _exitcode = 0;
static bool _stopWait = false;

/**
 *
 */
void test_start(const char* desc) {
    LOG_INFO("\n==================================================");
    LOG_INFO("[TEST] %s", desc);
    LOG_INFO("[PID] %d", GetCurrentProcessId());
    LOG_INFO("==================================================\n");

    // Associate current thread as the main thread.
    [[NSThread currentThread] _associateWithMainThread];
    _stopWait = false;
}

void test_stop_after_delay(void* delay) {
#if HAVE_LEAKS
    int res;
    pid_t pid;
    char pidstr[10];
#endif

    if (delay != NULL) {
        Sleep((DWORD)(SIZE_T)delay * 1000);
    }

#if HAVE_LEAKS
    if (getenv("NOLEAKS"))
        _exit(EXIT_SUCCESS);

    /* leaks doesn't work against debug variant malloc */
    if (getenv("DYLD_IMAGE_SUFFIX"))
        _exit(EXIT_SUCCESS);

    snprintf(pidstr, sizeof(pidstr), "%d", getpid());
    char* args[] = { "./leaks-wrapper", pidstr, NULL };
    res = posix_spawnp(&pid, args[0], NULL, NULL, args, environ);
    if (res == 0 && pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        test_long("Leaks", status, 0);
    } else {
        perror(args[0]);
    }
#endif
    test_unblock();
}

void test_stop(void) {
    test_stop_after_delay((void*)(intptr_t)0);
}

void test_unblock(void) {
    _stopWait = true;
    [[NSRunLoop mainRunLoop] _stop];
    [[NSRunLoop mainRunLoop] _wakeUp];
}

void test_block_until_stopped(void) {
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];

    for (;;) {
        if (_stopWait) {
            break;
        }
        [runLoop run];
    }
}