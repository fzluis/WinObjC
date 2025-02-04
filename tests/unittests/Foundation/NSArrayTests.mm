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

#include <TestFramework.h>
#include <Foundation\Foundation.h>

void assertArrayContents(NSArray* array, NSObject* first, ...) {
    va_list args;
    va_start(args, first);

    id curVal = first;

    size_t i = 0;
    while (curVal != nil) {
        ASSERT_OBJCEQ(curVal, [array objectAtIndex:i++]);
        curVal = va_arg(args, id);
    }

    va_end(args);

    ASSERT_EQ(i, [array count]);
}

TEST(NSArray, ArrayWithObjects) {
    // Empty list
    assertArrayContents([NSArray arrayWithObjects:nil], nil);

    // Single element
    assertArrayContents([NSArray arrayWithObjects:@1, nil], @1, nil);

    // Multiple elements
    assertArrayContents([NSArray arrayWithObjects:@1, @2, @3, nil], @1, @2, @3, nil);
}

TEST(NSArray, InitWithObjects) {
    // Empty list
    assertArrayContents([[NSArray alloc] initWithObjects:nil], nil);

    // Single element
    assertArrayContents([[NSArray alloc] initWithObjects:@1, nil], @1, nil);

    // Multiple elements
    assertArrayContents([[NSArray alloc] initWithObjects:@1, @2, @3, nil], @1, @2, @3, nil);
}

@interface NSTestArray : NSArray
@end

@implementation NSTestArray
- (NSUInteger)count {
    return 5;
}

- (id)objectAtIndex:(NSUInteger)index {
    return @2;
}
@end

TEST(NSArray, Subclassable) {
    NSArray* testArray = [NSTestArray new];
    ASSERT_EQ(@2, testArray[0]);
    int sum = 0;
    for (id val in testArray) {
        sum += [(NSNumber*)val integerValue];
    }
    ASSERT_EQ(10, sum);

    NSArray* testArray2 = @[ @2, @2, @2, @2, @2 ];

    ASSERT_OBJCEQ(testArray, testArray2);
}

NS_OPTIONS(NSUInteger, NSMutableTestArrayCalls){ countCalled,     objectAtIndexCalled,       insertObjectCalled,
                                                 addObjectCalled, removeObjectAtIndexCalled, replaceObjectAtIndexCalled };

@interface NSMutableTestArray : NSMutableArray
@property unsigned int calledMethods;
@end

@implementation NSMutableTestArray
- (NSUInteger)count {
    _calledMethods |= countCalled;
    return 5;
}

- (id)objectAtIndex:(NSUInteger)index {
    _calledMethods |= objectAtIndexCalled;
    return @2;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    _calledMethods |= insertObjectCalled;
}

- (void)addObject:(id)anObject {
    _calledMethods |= addObjectCalled;
}

- (void)removeLastObject {
    // No test/flags for removeLastObject because it isn't called from any CF methods.
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    _calledMethods |= removeObjectAtIndexCalled;
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    _calledMethods |= replaceObjectAtIndexCalled;
}

- (void)verifyAndResetFlags:(unsigned int)expectedCalls {
    ASSERT_EQ(expectedCalls & countCalled, _calledMethods & countCalled);
    ASSERT_EQ(expectedCalls & objectAtIndexCalled, _calledMethods & objectAtIndexCalled);
    ASSERT_EQ(expectedCalls & insertObjectCalled, _calledMethods & insertObjectCalled);
    ASSERT_EQ(expectedCalls & addObjectCalled, _calledMethods & addObjectCalled);
    ASSERT_EQ(expectedCalls & removeObjectAtIndexCalled, _calledMethods & removeObjectAtIndexCalled);
    ASSERT_EQ(expectedCalls & replaceObjectAtIndexCalled, _calledMethods & replaceObjectAtIndexCalled);
    _calledMethods = 0;
}
@end

TEST(NSArray, NSMutableArray_Subclassable) {
    NSMutableTestArray* testArray = [NSMutableTestArray new];
    CFMutableArrayRef test = (CFMutableArrayRef)testArray;

    CFArrayGetCount(test);
    [testArray verifyAndResetFlags:countCalled];

    CFArrayGetValueAtIndex(test, 2);
    [testArray verifyAndResetFlags:objectAtIndexCalled];

    CFArrayInsertValueAtIndex(test, 2, @2);
    [testArray verifyAndResetFlags:insertObjectCalled];

    CFArrayAppendValue(test, @2);
    [testArray verifyAndResetFlags:addObjectCalled];

    CFArrayRemoveValueAtIndex(test, 5);
    [testArray verifyAndResetFlags:removeObjectAtIndexCalled];

    CFArraySetValueAtIndex(test, 4, @3);
    [testArray verifyAndResetFlags:replaceObjectAtIndexCalled];
}

TEST(NSArray, NSArray_initWithContentsOfFile) {
    NSArray* expectedArray = @[@1, @2, @3, @4, @5];

    NSArray* cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSAllDomainsMask, YES);
    ASSERT_NE(0, [cachesPaths count]);
    NSString* path = cachesPaths[0];
    NSString* file = [path stringByAppendingPathComponent:@"array.data"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];
    [expectedArray writeToFile:file atomically:NO];
    NSArray* actualArray = [[NSArray alloc] initWithContentsOfFile:file];
    ASSERT_OBJCEQ(expectedArray, actualArray);
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
}

TEST(NSArray, Enumerate) {
    __block NSArray* testArray = @[ @0, @1, @2, @3 ];

    [testArray enumerateObjectsWithOptions:0
                                usingBlock:^(id object, NSUInteger index, BOOL* stop) {
                                    ASSERT_EQ((unsigned)[(NSNumber*)[testArray objectAtIndex:index] integerValue], (unsigned)index);
                                }];

    __block unsigned expectedIndex = 3;
    // Verify that the NSReverseEnumeration option iterates in reverse
    [testArray enumerateObjectsWithOptions:NSEnumerationReverse
                                usingBlock:^(id object, NSUInteger index, BOOL* stop) {
                                    ASSERT_EQ(expectedIndex, index);
                                    ASSERT_EQ((unsigned)[(NSNumber*)[testArray objectAtIndex:index] integerValue], (unsigned)index);
                                    expectedIndex--;
                                }];

    // Verify that the NSEnumerationConcurrent option executes the blocks concurrently
    __block NSCondition* condition = [NSCondition new];
    __block unsigned waitingCount = 0;
    [testArray enumerateObjectsWithOptions:NSEnumerationConcurrent
                                usingBlock:^(id object, NSUInteger index, BOOL* stop) {
                                    [condition lock];
                                    waitingCount++;
                                    if (waitingCount == 4) {
                                        waitingCount--;
                                        [condition signal];
                                        [condition unlock];
                                        return;
                                    }
                                    [condition wait];
                                    waitingCount--;
                                    [condition signal];
                                    [condition unlock];
                                }];

    ASSERT_EQ(0, waitingCount);
}
