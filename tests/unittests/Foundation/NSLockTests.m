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
#import <Foundation/Foundation.h>
#import <thread>
#import <mutex>
#import <condition_variable>
#import <chrono>
#import "NSLock+Internal.h"

TEST(Foundation, NSLock_initWithName) {
    NSString* lockName = @"testLock";
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");
    [lock setName:lockName];
    ASSERT_OBJCEQ_MSG(lockName, [lock name], "FAILED: lock name does not match");
    ASSERT_EQ_MSG(0, [lock _lockCount], "FAILED: the lock should not be locked.");
    [lock release];
    [lockName release];
}

TEST(Foundation, NSLock_lockAndUnLock) {
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");
    [lock lock];
    ASSERT_EQ_MSG(1, [lock _lockCount], "FAILED: the lock should be locked.");
    [lock unlock];
    ASSERT_EQ_MSG(0, [lock _lockCount], "FAILED: the lock should not be locked.");
    [lock release];
}

TEST(Foundation, NSLock_lockAndUnLockSanity) {
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");
    int limit = 20;
    for (int i = 0; i < limit; ++i) {
        [lock lock];
        ASSERT_EQ_MSG(1, [lock _lockCount], "FAILED: the lock should be locked.");
        [lock unlock];
        ASSERT_EQ_MSG(0, [lock _lockCount], "FAILED: the lock should not be locked.");
    }

    [lock release];
}

TEST(Foundation, NSLock_tryLock) {
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");

    ASSERT_EQ_MSG(YES, [lock tryLock], "FAILED: unable to obtain the lock.");
    ASSERT_EQ_MSG(1, [lock _lockCount], "FAILED: the lock should be locked.");
    [lock unlock];

    ASSERT_EQ_MSG(0, [lock _lockCount], "FAILED: the lock should not be locked.");
    [lock release];
}
TEST(Foundation, NSLock_lockBeforeDate) {
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");

    ASSERT_EQ_MSG(YES, [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:4]], "FAILED: unable to obtain the lock.");
    ASSERT_EQ_MSG(1, [lock _lockCount], "FAILED: the lock should be locked.");
    [lock unlock];

    ASSERT_EQ_MSG(0, [lock _lockCount], "FAILED: the lock should not be locked.");
    [lock release];
}

TEST(Foundation, NSLock_lockAndUnlockWithThreads) {
    NSLock* lock = [[NSLock alloc] init];
    ASSERT_TRUE_MSG(lock != nil, "FAILED: lock should be non-null!");

    std::mutex consumerStartMutex;
    std::mutex waitForProducerMutex;
    std::condition_variable consumerCondition;
    std::unique_lock<std::mutex> consumerStartLock(consumerStartMutex);
    bool successfullyLocked = false;
    bool successfullyAwaitedTheProducer = false;
    bool notified = false;
    std::thread consumer([&]() {
        std::unique_lock<std::mutex> innerStartLock(consumerStartMutex);

        // grab the lock
        [lock lock];
        successfullyLocked = true;
        // notify the main thread, so it can move from the wait to spawn a producer.
        consumerCondition.notify_all();
        [lock unlock];
		innerStartLock.unlock();
        // wait for the producer to come up.
        std::unique_lock<std::mutex> waitForProducerLock(waitForProducerMutex);
        consumerCondition.wait(waitForProducerLock, [&]() { return notified; });
        successfullyAwaitedTheProducer = true;
        waitForProducerLock.unlock();
    });

    // assure consumer grabs the lock first.
    // We want to make sure that the consumer is already waiting for the condition variable
    // broadcast before we spin up the producer.
    consumerCondition.wait(consumerStartLock, [&]() { return successfullyLocked; });

    ASSERT_EQ_MSG(true, successfullyLocked, "FAILED: Unable to succesfully lock.");

    std::thread producer([&]() {
        [lock lock];
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        notified = true;
        std::unique_lock<std::mutex> uniqueLock(waitForProducerMutex);
        consumerCondition.notify_all();
        uniqueLock.unlock();
        [lock unlock];
    });

    consumer.join();
    producer.join();

    ASSERT_EQ_MSG(true, successfullyAwaitedTheProducer, "FAILED: Unable to wait for the producer.");

    [lock release];
}