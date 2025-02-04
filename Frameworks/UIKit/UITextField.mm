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
#import <StubReturn.h>

#import "CoreGraphics/CGContext.h"
#import "CGContextInternal.h"

#import <UIKit/UIView.h>
#import <UIKit/UIControl.h>
#import <Foundation/NSTimer.h>
#import <UIKit/UIViewController.h>
#import <Foundation/NSNotificationCenter.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIColor.h>
#import <UIKit/UITextField.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UITableViewCell.h>
#import "NSMutableString+Internal.h"
#import "UIResponderInternal.h"

NSString* const UITextFieldTextDidBeginEditingNotification = @"UITextFieldTextDidBeginEditingNotification";
NSString* const UITextFieldTextDidChangeNotification = @"UITextFieldTextDidChangeNotification";
NSString* const UITextFieldTextDidEndEditingNotification = @"UITextFieldTextDidEndEditingNotification";

extern float keyboardBaseHeight;
static const float INPUTVIEW_DEFAULT_HEIGHT = 200.f;

@implementation UITextField {
    idretaintype(NSString) _text;
    idretaintype(UIFont) _font;
    idretain _placeholder;
    idretain _background;
    idretaintype(UIColor) __textColor;
    idretaintype(UIColor) _tintColor;
    idretain _undoManager;
    idretaintype(UIImageView) _cursorBlink;
    idretain _popoverController, _inputController;
    NSTimer* _cursorTimer;
    id _delegate;
    UITextAlignment _alignment;
    idretaintype(UIView) _leftView, _rightView, _inputView, _inputAccessoryView;
    UITextBorderStyle _borderStyle;
    CGRect _leftViewRect;
    bool _notifiedBegin;
    UITextFieldViewMode _clearButtonMode;
    BOOL _isEditing;
    BOOL _secureTextMode;
    unsigned _returnKeyType;

    UIKeyboardType _keyboardType;
    int _showLastCharLen;
    int _showLastCharBlinkCount; //  Piggyback the disappearing password character on the cursor blink
}
- (void)setTextCentersHorizontally:(BOOL)center {
}

/**
 @Status Interoperable
*/
- (void)setText:(NSString*)text {
    if (text != nil) {
        _text = [text copy];
        [self setNeedsDisplay];
    } else {
        _text = nil;
    }
}

/**
 @Status Interoperable
*/
- (NSString*)text {
    return _text;
}

/**
 @Status Interoperable
*/
- (void)setFont:(UIFont*)font {
    _font = font;
}

/**
 @Status Interoperable
*/
- (UIFont*)font {
    return _font;
}

/**
 @Status Caveat
 @Notes May not be fully implemented
*/
- (instancetype)initWithCoder:(NSCoder*)coder {
    [super initWithCoder:coder];
    _font = [coder decodeObjectForKey:@"UIFont"];
    _alignment = (UITextAlignment)[coder decodeInt32ForKey:@"UITextAlignment"];
    UITextBorderStyle borderStyle = (UITextBorderStyle)[coder decodeInt32ForKey:@"UIBorderStyle"];
    [self setBorderStyle:borderStyle];
    _keyboardType = (UIKeyboardType)[coder decodeInt32ForKey:@"UIKeyboardType"];
    _secureTextMode = [coder decodeInt32ForKey:@"UISecureTextEntry"];
    //[self setBackgroundColor:[UIColor whiteColor]];
    _text = [coder decodeObjectForKey:@"UIText"];
    __textColor = [coder decodeObjectForKey:@"UITextColor"];
    if (_text == nil) {
        _text = @"";
    }
    if (__textColor == nil) {
        __textColor = [UIColor blackColor];
    }
    _placeholder = [coder decodeObjectForKey:@"UIPlaceholder"];
    _undoManager.attach([NSUndoManager new]);

    id image = [[UIImage imageNamed:@"/img/TextFieldCursor@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 0, 4, 0)];
    _cursorBlink.attach([[UIImageView alloc] initWithImage:image]);
    [_cursorBlink setHidden:TRUE];
    [self addSubview:_cursorBlink];
    [self setBackgroundColor:[UIColor clearColor]];
    return self;
}

/**
 @Status Interoperable
*/
- (instancetype)initWithFrame:(CGRect)frame {
    [super initWithFrame:frame];
    _font = [UIFont fontWithName:@"Helvetica" size:[UIFont labelFontSize]];
    __textColor = [UIColor blackColor];
    _text = @"";
    [self setOpaque:FALSE];
    _undoManager.attach([NSUndoManager new]);

    id image = [[UIImage imageNamed:@"/img/TextFieldCursor@2x.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:8];
    _cursorBlink.attach([[UIImageView alloc] initWithImage:image]);
    [_cursorBlink setHidden:TRUE];
    [self addSubview:_cursorBlink];
    [self setBackgroundColor:[UIColor clearColor]];
    return self;
}

/**
 @Status Stub
*/
- (void)setMinimumFontSize:(float)size {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)setTextColor:(UIColor*)color {
    __textColor = color;
    [self setNeedsDisplay];
}

/**
 @Status Interoperable
*/
- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

/**
 @Status Interoperable
*/
- (id)delegate {
    return _delegate;
}

/**
 @Status Interoperable
*/
- (void)setEditingDelegate:(id)delegate {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (void)setClearButtonMode:(UITextFieldViewMode)mode {
    UNIMPLEMENTED();
    _clearButtonMode = mode;
}

/**
 @Status Stub
*/
- (UITextFieldViewMode)clearButtonMode {
    UNIMPLEMENTED();
    return _clearButtonMode;
}

/**
 @Status Interoperable
*/
- (void)setTextAlignment:(UITextAlignment)alignment {
}

/**
 @Status Interoperable
*/
- (void)setBorderStyle:(UITextBorderStyle)style {
    _borderStyle = style;
    [self setNeedsDisplay];
}

/**
 @Status Interoperable
*/
- (UITextBorderStyle)borderStyle {
    return _borderStyle;
}

/**
 @Status Stub
*/
- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)setKeyboardType:(UIKeyboardType)type {
    _keyboardType = type;
}

/**
 @Status Interoperable
*/
- (UIKeyboardType)keyboardType {
    return _keyboardType;
}

/**
 @Status Stub
*/
- (void)setKeyboardAppearance:(UIKeyboardAppearance)appearance {
    UNIMPLEMENTED();
}

- (void)setReturnKeyType:(UIReturnKeyType)type {
    _returnKeyType = type;
}

- (UIReturnKeyType)returnKeyType {
    return (UIReturnKeyType)_returnKeyType;
}

/**
 @Status Stub
*/
- (void)setSpellCheckingType:(UITextSpellCheckingType)type {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)setPlaceholder:(NSString*)str {
    _placeholder = [str copy];
}

/**
 @Status Interoperable
*/
- (NSString*)placeholder {
    return _placeholder;
}

/**
 @Status Stub
*/
- (void)setEnablesReturnKeyAutomatically:(BOOL)type {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (void)setClearsOnBeginEditing:(BOOL)type {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (void)setAutocorrectionType:(UITextAutocorrectionType)type {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)setSecureTextEntry:(BOOL)secure {
    _secureTextMode = secure;
}

/**
 @Status Interoperable
*/
- (void)setBackground:(UIImage*)image {
    _background = image;
    [self setNeedsDisplay];
}

/**
 @Status Interoperable
*/
- (UIImage*)background {
    return _background;
}

/**
 @Status Interoperable
*/
- (void)drawRect:(CGRect)rect {
    id text = _text;
    id textColor = __textColor;
    bool _isPlaceholder = false;
    if (_text == nil || [_text length] == 0) {
        text = _placeholder;
        textColor = [UIColor lightGrayColor];
        _isPlaceholder = true;
    } else {
        if (_secureTextMode) {
            WORD* chars = (WORD*)IwMalloc(([text length] + 1) * sizeof(WORD));
            [text getCharacters:chars];
            for (unsigned i = 0; i < [text length] - _showLastCharLen; i++) {
                chars[i] = '*';
            }
            text = [NSString stringWithCharacters:chars length:[text length]];
            IwFree(chars);
        }
    }

    if (_borderStyle != UITextBorderStyleNone) {
        if ([[self layer] borderWidth] == 0.0f || _borderStyle == UITextBorderStyleRoundedRect) {
            switch (_borderStyle) {
                case UITextBorderStyleLine: {
                    // If a background image is set, it takes preference over all borderstyles and the background image is shown, except for
                    // UITextBorderStyleRoundedRect.
                    if (_background != nil) {
                        break;
                    }

                    rect = [self bounds];
                    rect.origin.x += 1.0f;
                    rect.origin.y += 1.0f;
                    rect.size.width -= 2.0f;
                    rect.size.height -= 2.0f;

                    CGContextRef curContext = UIGraphicsGetCurrentContext();

                    if ([self isFirstResponder]) {
                        CGContextSetStrokeColorWithColor(curContext,
                                                         (CGColorRef)(_tintColor ? [_tintColor CGColor] :
                                                                                   [[UIColor windowsControlFocusedColor] CGColor]));
                    } else {
                        CGContextSetStrokeColorWithColor(curContext, (CGColorRef)[UIColor blackColor]);
                    }
                    CGContextStrokeRect(curContext, rect);
                    break;
                }

                case UITextBorderStyleRoundedRect: {
                    rect = [self bounds];
                    id image =
                        [[UIImage imageNamed:@"/img/TextFieldRounded@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
                    rect = [self bounds];
                    [image drawInRect:rect];
                    break;
                }

                case UITextBorderStyleBezel: {
                    // If a background image is set, it takes preference over all borderstyles and the background image is shown, except for
                    // UITextBorderStyleRoundedRect.
                    if (_background != nil) {
                        break;
                    }

                    rect = [self bounds];
                    id image =
                        [[UIImage imageNamed:@"/img/TextFieldBezel@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
                    rect = [self bounds];
                    [image drawInRect:rect];
                } break;
            }
        }
    }

    // Out of the 4 border styles that ios supports now, UITextBorderStyleRoundedRect takes preference over background image, for all others
    // borderstyles if there is a background image, it is shown and not the borderstyle. This is the default behaviour in ios.
    if (_background != nil && _borderStyle != UITextBorderStyleRoundedRect) {
        rect = [self bounds];
        [_background drawInRect:rect];
    }

    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), (CGColorRef)textColor);

    CGSize size;

    rect = [self bounds];
    rect.origin.x += 5.0f;
    rect.size.width -= 10.0f;
    size = rect.size;

    if (text != nil) {
        size = [text sizeWithFont:_font constrainedToSize:CGSizeMake(size.width, size.height) lineBreakMode:UILineBreakModeClip];
    } else {
        size = [@"" sizeWithFont:_font constrainedToSize:CGSizeMake(size.width, size.height) lineBreakMode:UILineBreakModeClip];
    }

    rect.origin.x += _leftViewRect.size.width;
    EbrCenterTextInRectVertically(&rect, &size, _font);
    size = [text drawInRect:rect withFont:_font lineBreakMode:UILineBreakModeClip alignment:_alignment];

    if (text == nil) {
        size.width = 0;
    }
    switch (_alignment) {
        case UITextAlignmentCenter:
            rect.origin.x = rect.origin.x + rect.size.width / 2.0f - size.width / 2.0f;
            break;

        case UITextAlignmentRight:
            rect.origin.x = rect.origin.x + rect.size.width - size.width;
            break;
    }

    if (!_isPlaceholder) {
        rect.origin.x += size.width;
    }
    rect.size.width = 2;
    [_cursorBlink setFrame:rect];
}

/**
 @Status Interoperable
*/
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    if (_curState & UIControlStateDisabled) {
        return;
    }

    [self becomeFirstResponder];
}

/**
 @Status Interoperable
*/
- (void)deleteBackward {
    NSRange range;
    bool proceed = false;

    _showLastCharLen = 0;
    if (_text == nil) {
        _text = [NSMutableString new];
    }

    id oldString = [_text copy];
    id newString = [NSMutableString new];
    [newString setString:_text];

    id newChar = @"";

    range.location = [newString length];
    if (range.location > 0) {
        range.length = 1;
        range.location--;
        [newString deleteCharactersInRange:range];
        proceed = true;
    }

    if (proceed) {
        bool setText = true;
        if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            setText = [_delegate textField:self shouldChangeCharactersInRange:range replacementString:newChar] != FALSE;
        }

        if (setText) {
            _text = newString;
            [self sendActionsForControlEvents:UIControlEventEditingChanged];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UITextFieldTextDidChangeNotification" object:self];
            [self setNeedsDisplay];
        }
    }
}

- (void)_deleteRange:(NSNumber*)num {
    int numToDelete = [num intValue];

    for (int i = 0; i < numToDelete; i++) {
        [self deleteBackward];
    }
}

- (void)_keyPressed:(unsigned short)key {
    _showLastCharLen = 0;

    if (key != 13) {
        if (key == 8) {
            [self deleteBackward];
            return;
        }

        NSRange range;

        id newChar = [NSString stringWithCharacters:&key length:1];

        if (_text == nil) {
            _text = [NSMutableString new];
        }

        id oldString = [_text copy];
        id newString = [NSMutableString new];
        [newString setString:_text];

        [newString appendString:newChar];

        range.location = [newString length] - 1;
        range.length = 1;

        bool setText = true;
        if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            setText = [_delegate textField:self shouldChangeCharactersInRange:range replacementString:newChar] != FALSE;
        }

        if (setText) {
            _text = newString;
            [self sendActionsForControlEvents:UIControlEventEditingChanged];
            [self setNeedsDisplay];
        }
        _showLastCharLen = 1;
        _showLastCharBlinkCount = 3;
    } else {
        BOOL dismiss = TRUE;

        if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
            dismiss = FALSE;
            if ([_delegate textFieldShouldReturn:self]) {
                dismiss = TRUE;
            }
        }

        if (dismiss) {
            if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
                [_delegate textFieldDidEndEditing:self];
            }
            [self sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UITextFieldTextDidEndEditingNotification" object:self];

            [self resignFirstResponder];
        }
    }
}

/**
 @Status Stub
*/
- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjust {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)setLeftView:(UIView*)view {
    _leftView = view;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

/**
 @Status Stub
*/
- (void)setInputAccessoryView:(UIView*)view {
    UNIMPLEMENTED();
    _inputAccessoryView = view;
    [self setNeedsLayout];
}

/**
 @Status Stub
*/
- (UIView*)inputAccessoryView {
    UNIMPLEMENTED();
    return _inputAccessoryView;
}

/**
 @Status Stub
*/
- (void)setInputView:(UIView*)view {
    UNIMPLEMENTED();
    keyboardBaseHeight = INPUTVIEW_DEFAULT_HEIGHT;
    _inputView = view;
    [self setNeedsLayout];
    [[UIApplication sharedApplication] _keyboardChanged];
}

/**
 @Status Stub
*/
- (UIView*)inputView {
    UNIMPLEMENTED();
    return _inputView;
}

/**
 @Status Interoperable
*/
- (UIView*)leftView {
    return _leftView;
}

/**
 @Status Stub
*/
- (void)setLeftViewMode:(UITextFieldViewMode)mode {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (void)setRightView:(UIView*)view {
    UNIMPLEMENTED();
    _rightView = view;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

/**
 @Status Stub
*/
- (UIView*)rightView {
    UNIMPLEMENTED();
    return _rightView;
}

/**
 @Status Stub
*/
- (void)setRightViewMode:(UITextFieldViewMode)mode {
    UNIMPLEMENTED();
}

/**
 @Status Interoperable
*/
- (void)dealloc {
    _text = nil;
    _font = nil;
    _placeholder = nil;
    __textColor = nil;
    _background = nil;
    _undoManager = nil;
    _cursorBlink = nil;
    [_cursorTimer invalidate];
    _leftView = nil;
    _rightView = nil;
    _inputAccessoryView = nil;
    _inputView = nil;
    _inputController = nil;
    _tintColor = nil;
    [super dealloc];
}

/**
 @Status Interoperable
*/
- (void)layoutSubviews {
    [self setNeedsDisplay];
    if (_leftView != nil) {
        CGRect ourBounds;
        ourBounds = [self bounds];

        CGSize viewSize = { 0.0f, 0.0f };
        viewSize = [_leftView sizeThatFits:ourBounds.size];
        _leftViewRect.origin.x = 5.0f;
        _leftViewRect.size = viewSize;
        _leftViewRect.origin.y = ourBounds.size.height / 2.0f - _leftViewRect.size.height / 2.0f;
        [_leftView setFrame:_leftViewRect];
        [self addSubview:_leftView];
    }
}

- (void)_blinkCursor {
    if ([_cursorBlink isHidden]) {
        [_cursorBlink setHidden:FALSE];
    } else {
        [_cursorBlink setHidden:TRUE];
    }
    if (_showLastCharBlinkCount > 0) {
        _showLastCharBlinkCount--;
    } else {
        if (_showLastCharLen != 0) {
            _showLastCharLen = 0;
            [self setNeedsDisplay];
        }
    }
}

/**
 @Status Interoperable
*/
- (BOOL)becomeFirstResponder {
    if (_curState & UIControlStateDisabled) {
        return FALSE;
    }

    if ([self isFirstResponder]) {
        return TRUE;
    }

    if ([super becomeFirstResponder] == FALSE) {
        return FALSE;
    }

    if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        if (![_delegate textFieldShouldBeginEditing:self]) {
            return FALSE;
        }
    }

    if (_inputView && [_inputView respondsToSelector:@selector(sendActionsForControlEvents:)]) {
        [_inputView sendActionsForControlEvents:UIControlEventValueChanged];
    }

    [[UIApplication sharedApplication] _keyboardChanged];

    _cursorTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_blinkCursor) userInfo:0 repeats:TRUE];
    [_cursorBlink setHidden:FALSE];

    _isEditing = TRUE;

    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [_delegate textFieldDidBeginEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UITextFieldTextDidBeginEditingNotification" object:self];
    [self setNeedsDisplay];

    return TRUE;
}

/**
 @Status Interoperable
*/
- (BOOL)resignFirstResponder {
    if (![self isFirstResponder]) {
        return TRUE;
    }

    if (_isEditing) {
        if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
            if ([_delegate textFieldShouldEndEditing:self] == FALSE) {
                return FALSE;
            }
        }
    }
    [_cursorTimer invalidate];
    _cursorTimer = nil;

    [_cursorBlink setHidden:TRUE];

    if (_isEditing) {
        _showLastCharLen = 0;
        [self setNeedsDisplay];

        _isEditing = FALSE;
        [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
        if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
            [_delegate textFieldDidEndEditing:self];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UITextFieldTextDidEndEditingNotification" object:self];
    }
    [super resignFirstResponder];

    [[UIApplication sharedApplication] _keyboardChanged];

    return TRUE;
}

/**
 @Status Interoperable
*/
- (NSUndoManager*)undoManager {
    return _undoManager;
}

/**
 @Status Interoperable
*/
- (BOOL)isEditing {
    return _isEditing;
}

/**
 @Status Interoperable
*/
- (void)setTintColor:(UIColor*)color {
    _tintColor = color;
}

/**
 @Status Interoperable
*/
- (UIColor*)tintColor {
    return _tintColor;
}

/**
 @Status Interoperable
*/
- (CGSize)sizeThatFits:(CGSize)curSize {
    CGSize ret = { 0, 0 };

    if (_font == nil) {
        [self setFont:[UIFont fontWithName:@"Helvetica" size:[UIFont labelFontSize]]];
    }

    CGSize textSize = { 0 }, placeholderSize = { 0 };
    if (_text != nil) {
        textSize = [_text sizeWithFont:_font constrainedToSize:CGSizeMake(curSize.width, curSize.height) lineBreakMode:UILineBreakModeClip];
    }
    if (_placeholder != nil) {
        placeholderSize =
            [_placeholder sizeWithFont:_font constrainedToSize:CGSizeMake(curSize.width, curSize.height) lineBreakMode:UILineBreakModeClip];
    }

    if (textSize.width > placeholderSize.width) {
        ret = textSize;
    } else {
        ret = placeholderSize;
    }
    if (ret.height == 0.0f) {
        CGSize size;

        size = [@" " sizeWithFont:_font constrainedToSize:CGSizeMake(curSize.width, curSize.height) lineBreakMode:UILineBreakModeClip];
        ret.height = size.height;
    }

    return ret;
}

/**
 @Status Stub
*/
- (void)drawPlaceholderInRect:(CGRect)rect {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (void)drawTextInRect:(CGRect)rect {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (CGRect)borderRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)editingRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)rightViewRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)textRectForBounds:(CGRect)bounds {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (void)insertText:(NSString*)text {
    UNIMPLEMENTED();
}

/**
 @Status Stub
*/
- (BOOL)hasText {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition toPosition:(UITextPosition*)toPosition {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (UITextPosition*)positionFromPosition:(UITextPosition*)position offset:(NSInteger)offset {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)firstRectForRange:(UITextRange*)range {
    UNIMPLEMENTED();
    return StubReturn();
}

/**
 @Status Stub
*/
- (CGRect)caretRectForPosition:(UITextPosition*)position {
    UNIMPLEMENTED();
    return StubReturn();
}

@end
