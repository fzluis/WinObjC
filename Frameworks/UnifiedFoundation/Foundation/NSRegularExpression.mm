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
#include "Foundation/NSRegularExpression.h"
#include <unicode/regex.h>
#include <memory>

#import "LoggingNative.h"

@interface NSRegularExpression () {
    std::unique_ptr<RegexPattern> _icuRegex;
    NSMatchingOptions _replacementOptions;
}
@property (readwrite, copy) NSString* pattern;
@property (readwrite) NSRegularExpressionOptions options;
@property (readwrite) NSUInteger numberOfCaptureGroups;
@end

static StrongId<NSCharacterSet> s_patternMetaCharacters;
static StrongId<NSCharacterSet> s_templateMetaCharacters;

@implementation NSRegularExpression
/**
 @Status Interoperable
*/
+ (void)initialize {
    s_patternMetaCharacters = [NSCharacterSet characterSetWithCharactersInString:@"$^*()+/?[{}.\\"];
    s_templateMetaCharacters = [NSCharacterSet characterSetWithCharactersInString:@"$\\"];
}

/**
@Status Interoperable
*/
+ (NSRegularExpression*)regularExpressionWithPattern:(NSString*)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error {
    return [[[self alloc] initWithPattern:pattern options:options error:error] autorelease];
}

// Helper function for evaluating option and flag membership
static bool _evaluateOptionOrFlag(NSUInteger expectedOption, NSUInteger userOptions) {
    return (expectedOption & userOptions) != 0;
}

static const wchar_t* TAG = L"NSRegularExpression";
// Helper function for logging an ICU error code.
static bool _U_LogIfError(UErrorCode status) {
    if (U_FAILURE(status)) {
        TraceError(TAG, L"ICU Status Error. Error Code : %hs.", u_errorName(status));
        return true;
    }
    return false;
}

/**
 @Status Interoperable
*/
- (instancetype)initWithPattern:(NSString*)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error {
    if (self = [super init]) {
        _pattern = [pattern copy];

        int icuRegexOptions = 0;
        if (_evaluateOptionOrFlag(NSRegularExpressionCaseInsensitive, options)) {
            icuRegexOptions |= UREGEX_CASE_INSENSITIVE;
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionAllowCommentsAndWhitespace, options)) {
            icuRegexOptions |= UREGEX_COMMENTS;
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionIgnoreMetacharacters, options)) {
            // TODO - VSO 6264731: UREGEX_LITERAL causes faliures in ICU. Workaround is to use escaped version of pattern.

            // icuRegexOptions |= UREGEX_LITERAL;
            _pattern = [[NSRegularExpression escapedPatternForString:pattern] retain];
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionDotMatchesLineSeparators, options)) {
            icuRegexOptions |= UREGEX_DOTALL;
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionAnchorsMatchLines, options)) {
            icuRegexOptions |= UREGEX_MULTILINE;
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionUseUnixLineSeparators, options)) {
            icuRegexOptions |= UREGEX_UNIX_LINES;
        }
        if (_evaluateOptionOrFlag(NSRegularExpressionUseUnicodeWordBoundaries, options)) {
            icuRegexOptions |= UREGEX_UWORD;
        }

        // Create backing ICU regex handle:
        UStringHolder unicodePattern(_pattern);
        UErrorCode status = U_ZERO_ERROR;
        UParseError parseStatus;

        _icuRegex.reset(RegexPattern::compile(unicodePattern.string(), icuRegexOptions, parseStatus, status));

        if (_U_LogIfError(status)) {
            if (error) {
                *error = (NSError*)[NSError errorWithDomain:NSCocoaErrorDomain code:2048 userInfo:nil];
            }
            [self release];
            return nil;
        } else {
            if (error) {
                *error = nil;
            }
        }

        RegexMatcher* matcher = _icuRegex->matcher(status);
        _numberOfCaptureGroups = matcher->groupCount();
        delete matcher;
    }

    return self;
}

/**
 @Status Interoperable
*/
- (void)dealloc {
    [_pattern release];

    [super dealloc];
}

// Helper function for setting ICU Regex options.
static void _setMatcherOptions(RegexMatcher& icuRegex, int options) {
    // Set transparent bounds
    if (_evaluateOptionOrFlag(NSMatchingWithTransparentBounds, options)) {
        icuRegex.useTransparentBounds(true);
    }

    // Without anchoring bounds
    if (!(_evaluateOptionOrFlag(NSMatchingWithoutAnchoringBounds, options))) {
        icuRegex.useAnchoringBounds(true);
    } else {
        icuRegex.useAnchoringBounds(false);
    }
}

/**
 @Status Interoperable
*/
- (NSUInteger)numberOfMatchesInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    __block NSUInteger count = 0;

    [self enumerateMatchesInString:string
                           options:options
                             range:range
                        usingBlock:^void(NSTextCheckingResult* textResult, NSMatchingFlags flags, BOOL* stop) {
                            if (textResult) {
                                count++;
                            }
                        }];

    return count;
}

/**
 @Status Interoperable
*/
- (NSTextCheckingResult*)firstMatchInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    NSRange tempRange = NSMakeRange(NSNotFound, 0);
    __block NSTextCheckingResult* result =
        [[NSTextCheckingResult regularExpressionCheckingResultWithRanges:&tempRange count:1 regularExpression:self] retain];

    [self enumerateMatchesInString:string
                           options:options
                             range:range
                        usingBlock:^void(NSTextCheckingResult* textResult, NSMatchingFlags flags, BOOL* stop) {
                            if (textResult) {
                                result = [textResult retain];
                                *stop = YES;
                            }
                        }];

    return [result autorelease];
}

/**
 @Status Interoperable
*/
- (NSRange)rangeOfFirstMatchInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    __block NSRange result = { NSNotFound, 0 };

    [self enumerateMatchesInString:string
                           options:options
                             range:range
                        usingBlock:^void(NSTextCheckingResult* textResult, NSMatchingFlags flags, BOOL* stop) {
                            if (textResult) {
                                result = textResult.range;
                                *stop = YES;
                            }
                        }];

    return result;
}

/**
 @Status Interoperable
*/
- (NSArray*)matchesInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    __block NSMutableArray* result = [NSMutableArray array];

    [self enumerateMatchesInString:string
                           options:options
                             range:range
                        usingBlock:^void(NSTextCheckingResult* textResult, NSMatchingFlags flags, BOOL* stop) {
                            if (textResult) {
                                [result addObject:textResult];
                            }
                        }];

    return result;
}

static NSUInteger _replaceAll(
    NSMutableString* string, NSRegularExpression* regex, RegexMatcher& icuRegex, NSString* replacement, UErrorCode status) {
    if (_U_LogIfError(status)) {
        return 0;
    }

    NSUInteger count = 0;
    int offset = 0;

    while (icuRegex.find() && status == U_ZERO_ERROR) {
        NSString* replacedText = nil;
        NSTextCheckingResult* result = nil;

        NSRange foundRange = NSMakeRange(icuRegex.start(status), icuRegex.end(status));
        if (_U_LogIfError(status)) {
            return count;
        }

        result = [NSTextCheckingResult regularExpressionCheckingResultWithRanges:&foundRange count:1 regularExpression:regex];

        replacedText = [regex replacementStringForResult:result inString:string offset:offset template:replacement];

        if (replacedText == nil) {
            return count;
        }

        [string replaceCharactersInRange:foundRange withString:replacedText];

        offset += replacedText.length - foundRange.length;
        count++;
    }
    return count;
}

/**
 @Status Interoperable
*/
- (NSUInteger)replaceMatchesInString:(NSMutableString*)string
                             options:(NSMatchingOptions)options
                               range:(NSRange)range
                        withTemplate:(NSString*)templateStr {
    if (string == nil) {
        return 0;
    }

    UStringHolder matchStr(string);

    UErrorCode status = U_ZERO_ERROR;
    RegexMatcher* matcher = _icuRegex->matcher(matchStr.string(), status);
    if (_U_LogIfError(status)) {
        return 0;
    }

    matcher->region(range.location, range.location + range.length, status);
    if (_U_LogIfError(status)) {
        return 0;
    }

    _setMatcherOptions(*matcher, options);

    @synchronized(self) {
        _replacementOptions = options;
        NSUInteger returnval = _replaceAll(string, self, *matcher, templateStr, status);
        _replacementOptions = 0;
        return returnval;
    }
}

/**
 @Status Interoperable
*/
- (NSString*)stringByReplacingMatchesInString:(NSString*)string
                                      options:(NSMatchingOptions)options
                                        range:(NSRange)range
                                 withTemplate:(NSString*)templateStr {
    // This is just a non-mutable version of replaceMatchesInString
    NSMutableString* mutableStr = [string mutableCopy];
    [self replaceMatchesInString:mutableStr options:options range:range withTemplate:templateStr];
    return [mutableStr autorelease];
}

static NSString* _escapeStringForCharacterSet(NSString* string, NSCharacterSet* set) {
    NSUInteger length = string.length;
    NSMutableString* returnVal = [NSMutableString stringWithCapacity:length * 2];

    const char* buffer = string.UTF8String;

    int lastTouchedCharacterIndex = -1;

    // For each character in buffer, check if it's a metacharacter that needs to be escaped.
    for (int i = 0; i < length; i++) {
        if ([set characterIsMember:buffer[i]]) {
            if (lastTouchedCharacterIndex != (i - 1)) {
                // Get substring that we can append now up to this point.
                NSString* part = [[NSString alloc] initWithBytesNoCopy:(void*)(buffer + (lastTouchedCharacterIndex + 1))
                                                                length:(i - (lastTouchedCharacterIndex + 1))
                                                              encoding:NSUTF8StringEncoding
                                                          freeWhenDone:false];

                [returnVal appendString:part];
                [part release];
            }
            lastTouchedCharacterIndex = i;

            // Append escaped metacharacter
            [returnVal appendFormat:@"\\%c", buffer[i]];
        }
    }

    // If nothing was escaped return original string
    if (lastTouchedCharacterIndex == -1) {
        return string;
    } else if (lastTouchedCharacterIndex != length - 1) {
        // Get the rest of the characters that weren't escaped.
        // Length is the length everything between i and the last encoded character exclusively.

        NSString* part = [[NSString alloc] initWithBytesNoCopy:(void*)(buffer + (lastTouchedCharacterIndex + 1))
                                                        length:(length - (lastTouchedCharacterIndex + 1))
                                                      encoding:NSUTF8StringEncoding
                                                  freeWhenDone:false];

        [returnVal appendString:part];
        [part release];
    }

    return returnVal;
}

/**
 @Status Interoperable
*/
+ (NSString*)escapedTemplateForString:(NSString*)string {
    return _escapeStringForCharacterSet(string, s_templateMetaCharacters);
}

/**
 @Status Interoperable
*/
+ (NSString*)escapedPatternForString:(NSString*)string {
    return _escapeStringForCharacterSet(string, s_patternMetaCharacters);
}

struct CallBackContext {
    BOOL* stop;
    void (^block)(NSTextCheckingResult* result, NSMatchingFlags flags, BOOL* stop);

    // This callback services NSMatchingProgress where the second argument does not matter.
    // Two callbacks are serviced with slightly different args, only the first of which we care about.
    template <typename... Args>
    static UBool matchCallback(const void* context, Args... args) {
        // cast context to struct type
        auto callbackStruct = reinterpret_cast<const CallBackContext*>(context);

        // call block with struct's stop
        callbackStruct->block(nil, NSMatchingProgress, callbackStruct->stop);

        // return stop...?
        return !(*callbackStruct->stop);
    }
};

/**
 @Status Interoperable
*/
- (void)enumerateMatchesInString:(NSString*)string
                         options:(NSMatchingOptions)options
                           range:(NSRange)range
                      usingBlock:(void (^)(NSTextCheckingResult* result, NSMatchingFlags flags, BOOL* stop))block {
    UErrorCode status = U_ZERO_ERROR;

    UStringHolder matchStr(string);

    RegexMatcher* matcher = _icuRegex->matcher(matchStr.string(), status);
    if (_U_LogIfError(status)) {
        return;
    }

    BOOL stop = NO;
    CallBackContext context = { &stop, block };

    // Set callbacks for reporting progress
    if (options & NSMatchingReportProgress) {
        matcher->setMatchCallback(&CallBackContext::matchCallback<int32_t>, &context, status);
        if (_U_LogIfError(status)) {
            return;
        }

        matcher->setFindProgressCallback(&CallBackContext::matchCallback<int64_t>, &context, status);
        if (_U_LogIfError(status)) {
            return;
        }
    }

    NSTextCheckingResult* result;
    NSMatchingFlags flags = 0;

    matcher->region(range.location, range.location + range.length, status);

    if (_U_LogIfError(status)) {
        return;
    }

    _setMatcherOptions(*matcher, options);

    bool anchorMatch = _evaluateOptionOrFlag(NSMatchingAnchored, options);

    // Find matches, if match do block
    while (matcher->find() && !stop) {
        flags = 0;

        // TODO: ICU 48 does not support find(status) implemented in ICU 55. This is required for accurate NSMatchingInternalError flagging
        if (_U_LogIfError(status)) {
            flags |= NSMatchingInternalError;
            block(result, flags, &stop);
        } else {
            // Create NSTextCheckingResult
            int startpos = matcher->start(status);
            if (_U_LogIfError(status)) {
                block(result, NSMatchingInternalError, &stop);
                break;
            }

            int endpos = matcher->end(status);
            if (_U_LogIfError(status)) {
                block(result, NSMatchingInternalError, &stop);
                break;
            }

            NSRange foundRange = NSMakeRange(startpos, endpos - startpos);
            if (!anchorMatch || (anchorMatch && foundRange.location == range.location)) {
                result = [NSTextCheckingResult regularExpressionCheckingResultWithRanges:&foundRange count:1 regularExpression:self];

                if (matcher->requireEnd()) {
                    flags |= NSMatchingRequiredEnd;
                }

                if (matcher->hitEnd()) {
                    flags |= NSMatchingHitEnd;
                }
                block(result, flags, &stop);
            }
        }

        status = U_ZERO_ERROR;
    }

    if (_evaluateOptionOrFlag(NSMatchingCompleted, options)) {
        flags |= NSMatchingCompleted;
        block(result, flags, &stop);
    }
}

/**
 @Status Caveat
 @Notes Uses ICU's formatting to make replacements.
*/
- (NSString*)replacementStringForResult:(NSTextCheckingResult*)result
                               inString:(NSString*)string
                                 offset:(NSInteger)offset
                               template:(NSString*)templateStr {
    // get range from result
    NSRange range = result.range;

    UStringHolder tempStr(templateStr);
    UnicodeString replacedString;
    const UnicodeString unicodeTemplate = tempStr.string();
    UErrorCode status = U_ZERO_ERROR;

    UStringHolder newUString(string);

    // TODO 6620456: replacementStringForResult Should Format and Build String Itself
    // Create a new RegexMatcher by re-using the ivar pattern.
    RegexMatcher* matcher = _icuRegex->matcher(newUString.string(), status);
    if (_U_LogIfError(status)) {
        return nil;
    }

    // Set its region to the result's range
    matcher->region(range.location + offset, range.location + range.length + offset, status);
    if (_U_LogIfError(status)) {
        return nil;
    }

    _setMatcherOptions(*matcher, _replacementOptions);

    // Find the match
    matcher->find();

    // Replace the match
    matcher->appendReplacement(replacedString, unicodeTemplate, status);

    if (_U_LogIfError(status)) {
        return nil;
    }

    // Return only the replaced string
    std::string str;
    replacedString.toUTF8String(str);

    return [NSString stringWithUTF8String:str.c_str()];
}

/**
 @Status Interoperable
*/
- (instancetype)copyWithZone:(NSZone*)zone {
    return [self retain];
}

/**
 @Status Interoperable
*/
- (instancetype)initWithCoder:(NSCoder*)coder {
    NSString* pattern = [[coder decodeObjectForKey:@"pattern"] retain];
    NSUInteger options = [coder decodeIntegerForKey:@"options"];

    return [self initWithPattern:pattern options:options error:nullptr];
}

/**
 @Status Interoperable
*/
- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:_pattern forKey:@"pattern"];
    [coder encodeInteger:_options forKey:@"options"];
}

/**
 @Status Interoperable
*/
+ (BOOL)supportsSecureCoding {
    return YES;
}

@end