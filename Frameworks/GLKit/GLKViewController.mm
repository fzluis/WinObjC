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

#import <Starboard.h>
#import <GLKit/GLKitExport.h>
#import <GLKit/GLKView.h>
#import <GLKit/GLKViewController.h>

#import <UWP/WindowsFoundation.h>
#import <UWP/WindowsGlobalization.h>

@protocol _GLKViewControllerInformal <NSObject>
- (BOOL)_renderFrame;
@end

@implementation GLKViewController {
    CADisplayLink* _link;
    int64_t _firstStart;
    int64_t _lastStart;
    int64_t _lastFrame;
    WGCalendar* _calendar;
    BOOL _isGlkView;
}

/**
 @Status Interoperable
 @Public No
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.view isKindOfClass:[GLKView class]]) {
        _isGlkView = YES;
        GLKView* kv = (GLKView*)self.view;
        kv.enableSetNeedsDisplay = FALSE;
    }

    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(_renderFrame)];
    [_link retain];

    _calendar = [WGCalendar make];
    [_calendar setToNow];
    WFDateTime* dt = [_calendar getDateTime];
    _firstStart = dt.universalTime;
    _lastFrame = dt.universalTime;
}

- (void)dealloc {
    [_link release];
    [super dealloc];
}

/**
 @Status Interoperable
 @Public No
*/
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.delegate glkViewController:self willPause:FALSE];

    [_link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [_calendar setToNow];
    WFDateTime* dt = [_calendar getDateTime];
    _lastStart = dt.universalTime;
}

/**
 @Status Interoperable
 @Public No
*/
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.delegate glkViewController:self willPause:TRUE];

    [_link removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (BOOL)_renderFrame {
    [_calendar setToNow];
    WFDateTime* dt = [_calendar getDateTime];
    int64_t frameTime = dt.universalTime;

    _timeSinceFirstResume = static_cast<NSTimeInterval>(frameTime - _firstStart) * 0.0000001;
    _timeSinceLastResume = static_cast<NSTimeInterval>(frameTime - _lastStart) * 0.0000001;
    _timeSinceLastUpdate = static_cast<NSTimeInterval>(frameTime - _lastFrame) * 0.0000001;
    _timeSinceLastDraw = _timeSinceLastUpdate;

    _lastFrame = frameTime;

    id dest = self;
    if (self.delegate != nil) {
        dest = self.delegate;
    }

    // TODO: The view/view controller logic here is probably quite wrong.

    if ([dest respondsToSelector:@selector(glkViewControllerUpdate:)]) {
        [dest glkViewControllerUpdate:self];
    } else if ([dest respondsToSelector:@selector(update)]) {
        [dest update];
    }

    bool tryDirectRender = true;
    if ([self.view respondsToSelector:@selector(_renderFrame)]) {
        if ([(id<_GLKViewControllerInformal>)self.view _renderFrame]) {
            tryDirectRender = false;
        }
    }

    if (tryDirectRender) {
        if (_isGlkView && [dest respondsToSelector:@selector(glkView:drawInRect:)]) {
            [dest glkView:(GLKView*)self.view drawInRect:self.view.frame];
        }
    }

    _framesDisplayed++;

    return TRUE;
}

// TODO: implement me!

/**
 @Status Stub
*/
- (NSInteger)framesPerSecond {
    UNIMPLEMENTED();
    return 30;
}

/**
 @Status Stub
 @Notes
*/
- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    UNIMPLEMENTED();
}

@end
