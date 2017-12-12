//
//  Test_NimbusTest.m
//  Test_NimbusTest
//
//  Created by CPU12068 on 12/11/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HMUploadAdapter.h"

@interface HMUploadAdapter (Testing)
- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)maxCount;
@end

@interface Test_NimbusTest : XCTestCase


@end

@implementation Test_NimbusTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSexMaxConcurrentTaskCount {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    NSUInteger maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 3);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:0], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 0);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:1], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:999], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 999);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:1000], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1000);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:1001], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1000);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:NSUIntegerMax], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1000);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:NSUIntegerMax + 1], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 0);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:-1], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1000);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:-NSUIntegerMax], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 1);
    
    XCTAssertEqual([_uploadAdapter setMaxConcurrentTaskCount:-NSUIntegerMax - 1], YES);
    maxCount = _uploadAdapter.getMaxConcurrentTaskCount;
    XCTAssertEqual(maxCount, 0);
}

- (void)testCreateOneUploadTask {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    NSString *correctFilePath = [[NSBundle mainBundle] pathForResource:@"GoTiengViet" ofType:@"dmg"];
    [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                              filePath:correctFilePath header:nil completionHandler:^(HMURLUploadTask * _Nullable uploadTask, NSError *error) {
                                  if (error) {
                                      NSLog(@"%@", error);
                                  } else {
                                      XCTAssertNotNil(uploadTask);
                                  }
                                  
                                  [completionExpec fulfill];
                              } inQueue:nil];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

#pragma mark - Test 'UploadTaskWith...' Function

- (void)testCreateUploadTaskWithNilParameters {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    [_uploadAdapter uploadTaskWithHost:nil
                              filePath:nil
                                header:nil
                     completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                         XCTAssertNil(uploadTask);
                         [completionExpec fulfill];
                     }
                               inQueue:nil];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCreateUploadTaskWithEmptyParameters {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    [_uploadAdapter uploadTaskWithHost:@""
                              filePath:@""
                                header:nil
                     completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                         XCTAssertNil(uploadTask);
                         [completionExpec fulfill];
                     }
                               inQueue:nil];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCreateUploadTaskWithPriority {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC) ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *correctFilePath = [[NSBundle mainBundle] pathForResource:@"GoTiengViet" ofType:@"dmg"];
        
        dispatch_group_t group = dispatch_group_create();
        
        //Set priority = High
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityHigh);
                             dispatch_group_leave(group);
                         }
                                  priority:HMURLUploadTaskPriorityHigh
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [_uploadAdapter cancelAllTask];
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityMedium, @"Set uploadTask.priority = HMURLUploadTaskPriorityMedium but result is not equal");
                             dispatch_group_leave(group);
                         }
                                  priority:HMURLUploadTaskPriorityMedium
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        
        //Set priority = Medium
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [_uploadAdapter cancelAllTask];
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityMedium, @"Set uploadTask.priority = HMURLUploadTaskPriorityMedium but result is not equal");
                             dispatch_group_leave(group);
                         }
                                  priority:HMURLUploadTaskPriorityMedium
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        
        //Set priority = Low
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [_uploadAdapter cancelAllTask];
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityMedium, @"Set uploadTask.priority = HMURLUploadTaskPriorityMedium but result is not equal");
                             dispatch_group_leave(group);
                         }
                                  priority:HMURLUploadTaskPriorityMedium
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        
        //Set priority = -1
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [_uploadAdapter cancelAllTask];
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityLow, @"Set priority = -1, priority will be 'Low', but result is not equal");
                             dispatch_group_leave(group);
                         }
                                  priority:-1
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        
        //Set priority = 10
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [_uploadAdapter cancelAllTask];
        dispatch_group_enter(group);
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath
                                    header:@{@"Content-type": @"multipart"}
                         completionHandler:^(HMURLUploadTask *uploadTask, NSError *error) {
                             XCTAssertNotNil(uploadTask);
                             XCTAssertEqual(uploadTask.priority, HMURLUploadTaskPriorityLow, @"Set priority = -1, priority will be 'Low', but result is not equal");
                             dispatch_group_leave(group);
                         }
                                  priority:10
                                   inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        [completionExpec fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCreateMultipleUploadTaskWithSameHostAndFilePath {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    
    __block HMURLUploadTask *onlyTask = nil;
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    NSString *correctFilePath = [[NSBundle mainBundle] pathForResource:@"GoTiengViet" ofType:@"dmg"];
    for (int i = 0; i < 10; i ++) {
        [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                  filePath:correctFilePath header:nil completionHandler:^(HMURLUploadTask * _Nullable uploadTask, NSError *error) {
                                      XCTAssertNotNil(uploadTask);
                                      
                                      if (!onlyTask) {
                                          onlyTask = uploadTask;
                                      } else {
                                          XCTAssertEqualObjects(onlyTask, uploadTask);
                                      }
                                      
                                      if (i == 9) {
                                          [completionExpec fulfill];
                                      }
                                  } inQueue:nil];
    }

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCreateMultipleUploadTaskWithMultipleThreadSameHostAndFilePath {
    HMUploadAdapter *_uploadAdapter = [[HMUploadAdapter alloc] initWithMaxConcurrentTaskCount:3];
    
    __block HMURLUploadTask *onlyTask = nil;
    XCTestExpectation *completionExpec = [self expectationWithDescription:@"Create upload task"];
    NSString *correctFilePath = [[NSBundle mainBundle] pathForResource:@"GoTiengViet" ofType:@"dmg"];
    for (int i = 0; i < 10; i ++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [_uploadAdapter uploadTaskWithHost:@"https://api.cloudinary.com/v1_1/ngochung/image/upload?upload_preset=ngochung"
                                      filePath:correctFilePath header:nil completionHandler:^(HMURLUploadTask * _Nullable uploadTask, NSError *error) {
                                          XCTAssertNotNil(uploadTask);
                                          
                                          if (!onlyTask) {
                                              onlyTask = uploadTask;
                                          } else {
                                              XCTAssertEqualObjects(onlyTask, uploadTask);
                                          }
                                          
                                          if (i == 9) {
                                              [completionExpec fulfill];
                                          }
                                      } inQueue:nil];
        });
    }
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
