//
//  NITRecipeTrackSenderTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITRecipeTrackSender.h"
#import "NITConfiguration.h"
#import "NITRecipeHistory.h"
#import "NITTrackManager.h"
#import "NITDateManager.h"
#import "NITTrackingInfo.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

NSString *const RECIPE_ID = @"recipe-id";
NSString *const PROFILE_ID = @"profile-id";
NSString *const INSTALLATION_ID = @"installation-id";
NSString *const APP_ID = @"app-id";

@interface NITRecipeTrackSenderTest : NITTestCase

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *history;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) NITDateManager *dateManager;

@end

@implementation NITRecipeTrackSenderTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.configuration = mock([NITConfiguration class]);
    self.history = mock([NITRecipeHistory class]);
    self.trackManager = mock([NITTrackManager class]);
    self.dateManager = mock([NITDateManager class]);
    
    [given(self.configuration.profileId) willReturn:PROFILE_ID];
    [given(self.configuration.installationId) willReturn:INSTALLATION_ID];
    [given(self.configuration.appId) willReturn:APP_ID];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSendNotified {
    NITRecipeTrackSender *sender = [[NITRecipeTrackSender alloc] initWithConfiguration:self.configuration history:self.history trackManager:self.trackManager dateManager:self.dateManager];
    NITTrackingInfo *trackingInfo = [NITTrackingInfo trackingInfoFromRecipeId:RECIPE_ID];
    [sender sendTrackingWithTrackingInfo:trackingInfo event:NITRecipeNotified];
    
    [verifyCount(self.history, times(1)) markRecipeAsShownWithId:RECIPE_ID];
    [verifyCount(self.trackManager, times(1)) addTrackWithRequest:anything()];
}

- (void)testSendEngaged {
    NITRecipeTrackSender *sender = [[NITRecipeTrackSender alloc] initWithConfiguration:self.configuration history:self.history trackManager:self.trackManager dateManager:self.dateManager];
    NITTrackingInfo *trackingInfo = [NITTrackingInfo trackingInfoFromRecipeId:RECIPE_ID];
    [sender sendTrackingWithTrackingInfo:trackingInfo event:NITRecipeEngaged];
    
    [verifyCount(self.history, never()) markRecipeAsShownWithId:RECIPE_ID];
    [verifyCount(self.trackManager, times(1)) addTrackWithRequest:anything()];
}

- (void)testSendCustom {
    NITRecipeTrackSender *sender = [[NITRecipeTrackSender alloc] initWithConfiguration:self.configuration history:self.history trackManager:self.trackManager dateManager:self.dateManager];
    NITTrackingInfo *trackingInfo = [NITTrackingInfo trackingInfoFromRecipeId:RECIPE_ID];
    [sender sendTrackingWithTrackingInfo:trackingInfo event:@"custom"];
    
    [verifyCount(self.history, never()) markRecipeAsShownWithId:RECIPE_ID];
    [verifyCount(self.trackManager, times(1)) addTrackWithRequest:anything()];
}

- (void)testSendNotifiedWithMissingProfileId {
    [given(self.configuration.profileId) willReturn:nil];
    NITRecipeTrackSender *sender = [[NITRecipeTrackSender alloc] initWithConfiguration:self.configuration history:self.history trackManager:self.trackManager dateManager:self.dateManager];
    NITTrackingInfo *trackingInfo = [NITTrackingInfo trackingInfoFromRecipeId:RECIPE_ID];
    [sender sendTrackingWithTrackingInfo:trackingInfo event:NITRecipeNotified];
    
    [verifyCount(self.history, times(1)) markRecipeAsShownWithId:RECIPE_ID];
    [verifyCount(self.trackManager, never()) addTrackWithRequest:anything()];
}

@end
