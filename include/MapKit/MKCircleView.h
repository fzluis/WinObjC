//******************************************************************************
//
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
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
#pragma once

#import <MapKit/MapKitExport.h>
#import <Foundation/NSObject.h>
#import <UIKit/UIAppearance.h>
#import <MapKit/MKOverlayPathView.h>

// TODO: Remove me when the protocol exists in UIKit
@protocol UICoordinateSpace
@end

// TODO: Remove me when the protocol exists in UIKit
@protocol UIDynamicItem
@end

// TODO: Remove me when the protocol exists in UIKit
@protocol UIFocusEnvironment
@end

// TODO: Remove me when the protocol exists in UIKit
@protocol UITraitEnvironment
@end

@class MKCircle;

MAPKIT_EXPORT_CLASS
@interface MKCircleView : MKOverlayPathView <NSCoding,
                                             NSObject,
                                             UIAppearance,
                                             UIAppearanceContainer,
                                             UICoordinateSpace,
                                             UIDynamicItem,
                                             UIFocusEnvironment,
                                             UITraitEnvironment>
- (instancetype)initWithCircle:(MKCircle*)circle STUB_METHOD;
@property (readonly, nonatomic) MKCircle* circle STUB_PROPERTY;
@end
