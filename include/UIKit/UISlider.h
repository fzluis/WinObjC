//
//  UISlider.h
//  UIKit
//
//  Created by Peter Steinberger on 24.03.11.
//
/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
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

#import "UIControl.h"
#import <QuartzCore/QuartzCore.h>

@class UIImageView, UIImage;

UIKIT_EXPORT_CLASS
@interface UISlider : UIControl

@property (nonatomic) float value;
@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
@property (nonatomic, getter=isContinuous) BOOL continuous;
@property (nonatomic, retain) UIColor* minimumTrackTintColor;
@property (nonatomic, retain) UIColor* maximumTrackTintColor;
@property (nonatomic, retain) UIColor* thumbTintColor;

- (void)setThumbImage:(UIImage*)image forState:(UIControlState)state;
- (void)setMinimumTrackImage:(UIImage*)image forState:(UIControlState)state;
- (void)setMaximumTrackImage:(UIImage*)image forState:(UIControlState)state;

@end
