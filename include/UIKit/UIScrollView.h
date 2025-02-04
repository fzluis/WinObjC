/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Copyright (c) 2016 Microsoft Corporation. All rights reserved.
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

#import <UIKit/UIView.h>
#import <UIKit/UIScrollViewDelegate.h>

typedef enum : NSInteger {
    UIScrollViewIndicatorStyleDefault,
    UIScrollViewIndicatorStyleBlack,
    UIScrollViewIndicatorStyleWhite,
} UIScrollViewIndicatorStyle;

typedef enum : NSInteger {
    UIScrollViewKeyboardDismissModeNone,
    UIScrollViewKeyboardDismissModeOnDrag,
    UIScrollViewKeyboardDismissModeInteractive,
} UIScrollViewKeyboardDismissMode;

UIKIT_EXPORT const float UIScrollViewDecelerationRateNormal;
UIKIT_EXPORT const float UIScrollViewDecelerationRateFast;

@class UIScroller, UIImageView, UIScrollView, UIPanGestureRecognizer, UIScrollWheelGestureRecognizer, UIPinchGestureRecognizer;

UIKIT_EXPORT_CLASS
@interface UIScrollView : UIView <NSCoding,
                                  NSObject,
                                  UIAppearance,
                                  UIAppearanceContainer,
                                  UICoordinateSpace,
                                  UIDynamicItem,
                                  UIFocusEnvironment,
                                  UITraitEnvironment>

- (BOOL)touchesShouldBegin:(NSSet*)touches withEvent:(UIEvent*)event inContentView:(UIView*)view STUB_METHOD;
- (BOOL)touchesShouldCancelInContentView:(UIView*)view STUB_METHOD;
- (void)flashScrollIndicators STUB_METHOD;
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;
- (void)setContentOffset:(CGPoint)theOffset animated:(BOOL)animated;
- (void)setZoomScale:(CGFloat)scale animated:(BOOL)animated;
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

@property (nonatomic) BOOL alwaysBounceHorizontal;
@property (nonatomic) BOOL alwaysBounceVertical;
@property (nonatomic) BOOL bounces;
@property (nonatomic) BOOL bouncesZoom STUB_PROPERTY;
@property (nonatomic) BOOL canCancelContentTouches STUB_PROPERTY;
@property (nonatomic) BOOL delaysContentTouches STUB_PROPERTY;
@property (nonatomic) BOOL scrollsToTop STUB_PROPERTY;
@property (nonatomic) BOOL showsHorizontalScrollIndicator STUB_PROPERTY;
@property (nonatomic) BOOL showsVerticalScrollIndicator;
@property (nonatomic) CGFloat decelerationRate STUB_PROPERTY;
@property (nonatomic) CGFloat maximumZoomScale;
@property (nonatomic) CGFloat minimumZoomScale;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) UIEdgeInsets scrollIndicatorInsets STUB_PROPERTY;
@property (nonatomic) UIScrollViewIndicatorStyle indicatorStyle STUB_PROPERTY;
@property (nonatomic) UIScrollViewKeyboardDismissMode keyboardDismissMode STUB_PROPERTY;
@property (nonatomic, assign) BOOL pagingEnabled;
@property (nonatomic, assign) id<UIScrollViewDelegate> delegate;
@property (nonatomic, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled STUB_PROPERTY;
@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, readonly) UIPanGestureRecognizer* panGestureRecognizer;
@property (nonatomic, readonly) UIScrollWheelGestureRecognizer* scrollWheelGestureRecognizer; // non-standard
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating; // always returns NO
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;
@property (nonatomic, readonly, getter=isTracking) BOOL tracking; // always returns NO
@property (nonatomic, readonly, getter=isZoomBouncing) BOOL zoomBouncing; // always NO
@property (nonatomic, readonly, getter=isZooming) BOOL zooming;
@property (readonly, nonatomic) UIPinchGestureRecognizer* pinchGestureRecognizer STUB_PROPERTY;
@end
