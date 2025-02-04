/*
* Copyright (c) 2011, The Iconfactory. All rights reserved.
*
* Copyright (c) 2015 Microsoft Corporation. All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the documentation
*    and/or other materials provided with the distribution.
*
* 3. Neither the name of The Iconfactory nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
* BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
* OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIViewController.h>

enum : NSUInteger {
    UIPopoverArrowDirectionUp = 1UL << 0,
    UIPopoverArrowDirectionDown = 1UL << 1,
    UIPopoverArrowDirectionLeft = 1UL << 2,
    UIPopoverArrowDirectionRight = 1UL << 3,
    UIPopoverArrowDirectionAny =
        UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown | UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight,
    UIPopoverArrowDirectionUnknown = NSUIntegerMax
};
typedef NSUInteger UIPopoverArrowDirection;

@class UIView, UIPopoverController, UIBarButtonItem, UIPopoverView;
@protocol UIPopoverControllerDelegate;

@interface UIPopoverController : NSObject

- (id)initWithContentViewController:(UIViewController*)viewController;

- (void)setContentViewController:(UIViewController*)controller animated:(BOOL)animated;

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView*)view
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;
- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem*)item
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated;
- (void)dismissPopoverAnimated:(BOOL)animated;

@property (nonatomic) CGSize popoverContentSize;
@property (nonatomic, assign) id<UIPopoverControllerDelegate> delegate;
@property (nonatomic, retain) UIViewController* contentViewController;
@property (nonatomic, readonly, getter=isPopoverVisible) BOOL popoverVisible;
@property (nonatomic, copy) NSArray* passthroughViews;
@property (nonatomic, readonly) UIPopoverArrowDirection popoverArrowDirection;

@end
