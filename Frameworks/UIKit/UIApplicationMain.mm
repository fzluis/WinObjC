//******************************************************************************
//
// Copyright (c) 2015 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#include "Starboard.h"

#import <Foundation/NSMutableArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSAutoReleasePool.h>

#import <UIKit/UIViewController.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIFont.h>
#import <UIKit/UINib.h>

#import <UIKit/UIApplicationDelegate.h>

#import "NSThread-Internal.h"
#import "UIApplicationInternal.h"
#import "UIFontInternal.h"
#import "UIViewControllerInternal.h"
#import "UIInterface.h"
#import "LoggingNative.h"

static const wchar_t* TAG = L"UIApplicationMain";

@interface NSAutoreleasePoolWarn : NSAutoreleasePool
@end

@implementation NSAutoreleasePoolWarn
- (void)addObject:(id)obj {
    TraceVerbose(TAG, L"Autoreleasing a %hs in the toplevel pool that will never be freed", object_getClassName(obj));
    [super addObject:obj];
}
@end

void UIBecomeInactive() {
    UIApplication* app = [UIApplication sharedApplication];
    id<UIApplicationDelegate> curDelegate = [app delegate];

    if ([curDelegate respondsToSelector:@selector(applicationWillResignActive:)]) {
        [curDelegate applicationWillResignActive:app];
    }

    // Drain global dispatch queue before ceding control.
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                  ^{
                  });
}

UIInterfaceOrientation UIOrientationFromString(UIInterfaceOrientation curOrientation, NSString* str) {
    char* pOrientation = (char*)[str UTF8String];

    if (strcmp(pOrientation, "UIInterfaceOrientationLandscapeRight") == 0) {
        return UIInterfaceOrientationLandscapeRight;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationLandscapeRight") == 0) {
        return UIInterfaceOrientationLandscapeRight;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationLandscapeDefault") == 0) {
        if (curOrientation == UIInterfaceOrientationLandscapeLeft || curOrientation == UIInterfaceOrientationLandscapeRight) {
            return curOrientation;
        }

        return UIInterfaceOrientationLandscapeRight;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationPortrait") == 0) {
        return UIInterfaceOrientationPortrait;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationPortraitRight") == 0) {
        return UIInterfaceOrientationPortrait;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationLandscapeLeft") == 0) {
        return UIInterfaceOrientationLandscapeLeft;
    } else if (strcmp(pOrientation, "UIDeviceOrientationLandscapeLeft") == 0) {
        return UIInterfaceOrientationLandscapeLeft;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationLandscape") == 0) {
        if (curOrientation == UIInterfaceOrientationLandscapeLeft || curOrientation == UIInterfaceOrientationLandscapeRight) {
            return curOrientation;
        }

        return UIInterfaceOrientationLandscapeRight;
    } else if (strcmp(pOrientation, "") == 0) {
        TraceWarning(TAG, L"Warning: orientation is blank");
        return UIInterfaceOrientationLandscapeRight;
    } else if (strcmp(pOrientation, "UIInterfaceOrientationPortraitUpsideDown") == 0) {
        return UIInterfaceOrientationPortraitUpsideDown;
    } else {
        TraceWarning(TAG, L"Warning: Unsupported orientation %hs", pOrientation);
        assert(0);
    }

    return UIInterfaceOrientationPortrait;
}

UIDeviceOrientation newDeviceOrientation = UIDeviceOrientationUnknown;

BOOL _doShutdown = FALSE;
volatile bool g_uiMainRunning = false;
static NSAutoreleasePoolWarn* outerPool;

/**
 @Public No
*/
int UIApplicationMainInit(
    int argc, char* argv[], NSString* principalClassName, NSString* delegateClassName, UIInterfaceOrientation defaultOrientation) {
    // Make sure we reference classes we need:
    void ForceInclusion();
    ForceInclusion();

    [[NSThread currentThread] _associateWithMainThread];
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];

    outerPool = [NSAutoreleasePoolWarn new];
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    UIApplication* uiApplication;

    if (principalClassName == nil) {
        principalClassName = [infoDict objectForKey:@"NSPrincipalClass"];
    }

    if (principalClassName != nil) {
        char* pClassName = (char*)[principalClassName UTF8String];
        uiApplication = [objc_getClass(pClassName) new];
    } else {
        uiApplication = [UIApplication new];
    }

    id<UIApplicationDelegate> delegateApp;

    if (delegateClassName != nil) {
        char* pClassName = (char*)[delegateClassName UTF8String];
        delegateApp = [objc_getClass(pClassName) new];
    } else {
        delegateApp = [uiApplication delegate];
    }

    [uiApplication setDelegate:delegateApp];
    idretain rootController(nil);

    if (infoDict != nil) {
        NSArray* fonts = [infoDict objectForKey:@"UIAppFonts"];
        if (fonts != nil) {
            for (NSString* curFontName in fonts) {
                NSString* path = [[NSBundle mainBundle] pathForResource:curFontName ofType:nil];
                if (path != nil) {
                    NSData* data = [NSData dataWithContentsOfFile:path];
                    if (data != nil) {
                        UIFont* font = [UIFont fontWithData:data];
                        if (font != nil) {
                            [font _setName:[[path lastPathComponent] stringByDeletingPathExtension]];
                            CTFontManagerRegisterGraphicsFont((CGFontRef)font, NULL);
                        }
                    }
                }
            }
        }

        if (defaultOrientation != UIInterfaceOrientationUnknown) {
            [uiApplication setStatusBarOrientation:defaultOrientation];
            [uiApplication _setInternalOrientation:defaultOrientation];
        }

        NSNumber* statusBarHidden = [infoDict objectForKey:@"UIStatusBarHidden"];
        int hideStatusBar = 0;
        if (statusBarHidden != nil) {
            if ([statusBarHidden intValue] != 0) {
                hideStatusBar = 1;
            }
        }
        [uiApplication setStatusBarHidden:hideStatusBar];

        NSString* mainNibFile;

        if (GetCACompositor()->isTablet()) {
            mainNibFile = [infoDict objectForKey:@"NSMainNibFile~ipad"];
            if (mainNibFile == nil) {
                mainNibFile = [infoDict objectForKey:@"NSMainNibFile"];
            }
        } else {
            mainNibFile = [infoDict objectForKey:@"NSMainNibFile"];
        }

        if (mainNibFile != nil) {
            NSString* nibPath = [[NSBundle mainBundle] pathForResource:mainNibFile ofType:@"nib"];
            if (nibPath != nil) {
                NSArray* obj =
                    [[[UINib nibWithNibName:nibPath bundle:[NSBundle mainBundle]] instantiateWithOwner:uiApplication options:nil] retain];
                int count = [obj count];

                for (int i = 0; i < count; i++) {
                    NSObject* curObj = [obj objectAtIndex:i];

                    if ([curObj isKindOfClass:[UIViewController class]]) {
                        [reinterpret_cast<UIViewController*>(curObj) _setResizeToScreen:YES];
                        [reinterpret_cast<UIViewController*>(curObj) _doResizeToScreen];
                    }
                }
            }
        } else {
            NSString* storyBoardName = nil;
            if (GetCACompositor()->isTablet()) {
                storyBoardName = [infoDict objectForKey:@"UIMainStoryboardFile~ipad"];
            }

            if (storyBoardName == nil) {
                storyBoardName = [infoDict objectForKey:@"UIMainStoryboardFile"];
            }

            if (storyBoardName != nil) {
                UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:storyBoardName bundle:[NSBundle mainBundle]];
                UIViewController* viewController = [storyBoard instantiateInitialViewController];
                if (viewController != nil) {
                    [viewController _setResizeToScreen:1];
                    rootController = viewController;
                }
            }
        }
    }

    id<UIApplicationDelegate> curDelegate = [uiApplication delegate];
    if (curDelegate == nil) {
        [uiApplication setDelegate:uiApplication];
    }

    // VSO 5762132: Temporarily call -application:willFinishLaunchingWithOptions: here (before did(...):)
    if ([curDelegate respondsToSelector:@selector(application:willFinishLaunchingWithOptions:)]) {
        [curDelegate application:uiApplication willFinishLaunchingWithOptions:nil];
    }

    if ([curDelegate respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
        NSMutableDictionary* options = [NSMutableDictionary dictionary];

        [curDelegate application:uiApplication didFinishLaunchingWithOptions:nil];
    } else if ([curDelegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
        [curDelegate applicationDidFinishLaunching:uiApplication];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidFinishLaunchingNotification" object:uiApplication];

    if (rootController != nil) {
        [[uiApplication _popupWindow] setRootViewController:rootController];
        [rootController _doResizeToScreen];
        rootController = nil;
    }

    // TODO::
    // bug-nithishm-03172016 -  Sending applicationDidBecomeActive as part of application launch until 6910008 is root caused.
    if ([curDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [curDelegate applicationDidBecomeActive:uiApplication];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidBecomeActiveNotification" object:uiApplication];

    [[UIDevice currentDevice] performSelectorOnMainThread:@selector(setOrientation:) withObject:0 waitUntilDone:FALSE];
    [[UIDevice currentDevice] performSelectorOnMainThread:@selector(_setInitialOrientation) withObject:0 waitUntilDone:FALSE];
    g_uiMainRunning = true;

    if (newDeviceOrientation != 0) {
        [[UIDevice currentDevice] performSelectorOnMainThread:@selector(submitRotation) withObject:nil waitUntilDone:FALSE];
    }

    //  Make windows visible
    NSArray* windows = [[UIApplication sharedApplication] windows];

    int windowCount = [windows count];
    for (int i = 0; i < windowCount; i++) {
        UIWindow* curWindow = [windows objectAtIndex:i];
        [curWindow setHidden:FALSE];
    }

    //  Cycle through the runloop once before releasing our pool,
    //  so that any layouts or selectors get a chance to retain before
    //  objects get destroyed
    [runLoop runMode:@"kCFRunLoopDefaultMode" beforeDate:[NSDate distantPast]];
    [pool release];

    return 0;
}

/**
 @Public No
*/
int UIApplicationMainLoop() {
    [[NSThread currentThread] _associateWithMainThread];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];

    for (;;) {
        [runLoop run];
        TraceWarning(TAG, L"Warning: CFRunLoop stopped");
        if (_doShutdown) {
            break;
        }
    }
    UIBecomeInactive();
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(applicationWillTerminate:)]) {
        [[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationWillTerminateNotification"
                                                        object:[UIApplication sharedApplication]];

    TraceVerbose(TAG, L"Exiting uncleanly.");
    EbrShutdownAV();
    [outerPool release];

    return 0;
}

void UIApplicationMainHandleWindowVisibilityChangeEvent(bool isVisible) {
    [[UIApplication sharedApplication] _sendActiveStatus:((isVisible) ? YES : NO)];
}

void UIApplicationMainHandleHighMemoryUsageEvent() {
    [[UIApplication sharedApplication] _sendHighMemoryWarning];
}
