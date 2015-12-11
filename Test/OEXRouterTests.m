//
//  OEXRouterTests.m
//  edX
//
//  Created by Akiva Leffert on 4/23/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "edX-Swift.h"
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OEXAccessToken.h"
#import "OEXInterface.h"
#import "OEXMockCredentialStorage.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

@interface OEXRouterTests : XCTestCase

@property (strong, nonatomic) OEXSession* loggedInSession;

@end

@implementation OEXRouterTests

- (void)setUp {
    id <OEXCredentialStorage> credentialStore = [[OEXMockCredentialStorage alloc] init];
    [credentialStore saveAccessToken:[[OEXAccessToken alloc] init] userDetails:[OEXUserDetails freshUser]];
    self.loggedInSession = [[OEXSession alloc] initWithCredentialStore:credentialStore];
    [self.loggedInSession loadTokenFromStore];
}

- (void)testShowSplashWhenLoggedOut {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:nil styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertTrue(router.t_showingLogin);
    XCTAssertNil(router.t_navigationHierarchy);
}

- (void)testShowContentWhenLoggedIn {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertFalse(router.t_showingLogin);
    XCTAssertNotNil(router.t_navigationHierarchy);
}

- (void)testDrawerViewExists {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertTrue(router.t_hasDrawerController);
}

- (id)mockInterfaceWithCourses:(NSArray*)courses {
    OCMockObject* interface = OCMStrictClassMock([OEXInterface class]);
    for(OEXCourse* course in courses) {
        id stub = [interface stub];
        [stub courseWithID:course.course_id];
        [stub andReturn:course];
    }
    return interface;
}

- (void)testShowNewAnnouncement {
    OEXCourse* course = [OEXCourse accessibleTestCourse];
    id interface = [self mockInterfaceWithCourses:@[course]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    XCTestExpectation* expectation = [self expectationWithDescription: @"controller pushed"];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    [interface stopMocking];
}


- (void)testShowSameNewAnnouncement {
    OEXCourse* course = [OEXCourse accessibleTestCourse];
    id interface = [self mockInterfaceWithCourses:@[course]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];

    XCTestExpectation* expectation = [self expectationWithDescription: @"controller pushed"];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    expectation = [self expectationWithDescription: @"controller pushed"];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertEqual(router.t_navigationHierarchy.count, stackLength);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    [interface stopMocking];
}


- (void)testShowDifferentNewAnnouncement {
    OEXCourse* course = [OEXCourse accessibleTestCourse];
    OEXCourse* otherCourse = [OEXCourse accessibleTestCourse];
    id interface = [self mockInterfaceWithCourses:@[course, otherCourse]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    XCTestExpectation* expectation = [self expectationWithDescription: @"controller pushed"];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    
    stackLength = router.t_navigationHierarchy.count;
    
    expectation = [self expectationWithDescription: @"controller pushed"];
    [router showAnnouncementsForCourseWithID:otherCourse.course_id];
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    [interface stopMocking];
}


@end