//
//  NITRecipesManagerTest.m
//  NearITSDK
//
//  Created by Francesco Leoni on 28/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITRecipesManager.h"
#import "NITNetworkMock.h"
#import "NITRecipeCooler.h"
#import "NITCacheManager.h"

@interface NITRecipesManagerTest : NITTestCase<NITManaging>

@property (nonatomic, strong) XCTestExpectation *expectation;

@end

@implementation NITRecipesManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"response_online_recipe" ofType:@"json"];
    [NITNetworkMock sharedInstance].enabled = YES;
    [[NITNetworkMock sharedInstance] registerData:[NSData dataWithContentsOfFile:path] withTest:^BOOL(NSURLRequest * _Nonnull request) {
        if([request.URL.absoluteString containsString:@"/recipes/7d41504f-99e9-45e0-b272-a6fdd202b688/evaluate"]) {
            return YES;
        }
        return NO;
    }];
    path = [bundle pathForResource:@"response_pulse_evaluation" ofType:@"json"];
    [[NITNetworkMock sharedInstance] registerData:[NSData dataWithContentsOfFile:path] withTest:^BOOL(NSURLRequest * _Nonnull request) {
        if([request.URL.absoluteString containsString:@"/recipes/evaluate"]) {
            return YES;
        }
        return NO;
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testScheduling {
    NITRecipe *recipe = [self recipeWithContentsOfFile:@"simple_recipe"];
    XCTAssertNotNil(recipe);
    if(recipe == nil) {
        return;
    }
    
    BOOL isScheduled = [recipe isScheduledNow:[NSDate dateWithTimeIntervalSince1970:1488459686]]; // Thu, 02 Mar 2017 13:01:26 GMT
    XCTAssertTrue(isScheduled);
    
    isScheduled = [recipe isScheduledNow:[NSDate dateWithTimeIntervalSince1970:1495458086]]; // Mon, 22 May 2017 13:01:26 GMT
    XCTAssertFalse(isScheduled);
}

- (void)testOnlineEvaluation {
    self.expectation = [self expectationWithDescription:@"expectation"];
    
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"online_recipe"];
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] init];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    recipesManager.manager = self;
    
    [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"leave_place" pulseBundle:@"9712e11a-ef3a-4b34-bdf6-413a84146f2e"];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testOnlinePulseEvaluation {
    self.expectation = [self expectationWithDescription:@"expectation"];
    
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"online_recipe"];
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] init];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    recipesManager.manager = self;
    
    [recipesManager gotPulseWithPulsePlugin:@"beacon_forest" pulseAction:@"always_evaluated" pulseBundle:@"e11f58db-054e-4df1-b09b-d0cbe2676031"];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testRecipeCooler {
    NITRecipe *recipe1 = [[NITRecipe alloc] init];
    recipe1.ID = @"recipe1";
    recipe1.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:2.0]};
    
    NITRecipe *recipe2 = [[NITRecipe alloc] init];
    recipe2.ID = @"recipe2";
    recipe2.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:3.0]};
    
    NSArray<NITRecipe*> *recipes = @[recipe1, recipe2];
    
    NITCacheManager *cacheManager = [[NITCacheManager alloc] initWithAppId:@"testRecipeCooler"];
    NITRecipeCooler *cooler = [[NITRecipeCooler alloc] initWithCacheManager:cacheManager];
    [cooler markRecipeAsShownWithId:recipe1.ID];
    
    [NSThread sleepForTimeInterval:0.2];
    
    NSArray<NITRecipe*> *filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 0);
    
    [NSThread sleepForTimeInterval:1.5];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 1);
    [cooler markRecipeAsShownWithId:recipe2.ID];
    
    [NSThread sleepForTimeInterval:1.5];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 1);
    
    [NSThread sleepForTimeInterval:2.0];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 2);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation"];
    [cacheManager removeAllItemsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRecipeCoolerCacheEmpty {
    NITRecipe *recipe1 = [[NITRecipe alloc] init];
    recipe1.ID = @"recipe1";
    recipe1.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:2.0]};
    
    NITRecipe *recipe2 = [[NITRecipe alloc] init];
    recipe2.ID = @"recipe2";
    recipe2.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:3.0]};
    
    NITCacheManager *cacheManager = [[NITCacheManager alloc] initWithAppId:@"testRecipeCoolerCacheEmpty"];
    NITRecipeCooler *cooler = [[NITRecipeCooler alloc] initWithCacheManager:cacheManager];
    [cooler markRecipeAsShownWithId:recipe1.ID];
    
    NSDate *now = [NSDate date];
    [NSThread sleepForTimeInterval:0.5];
    
    NSDictionary<NSString*, NSNumber*> *log = [cacheManager loadDictionaryForKey:@"CoolerLogMap"];
    NSTimeInterval latestLog = [[cacheManager loadNumberForKey:@"CoolerLatestLog"] doubleValue];
    XCTAssertTrue([log count] == 1);
    XCTAssertTrue(now.timeIntervalSince1970 - latestLog < 1);
    XCTAssertNotNil([log objectForKey:recipe1.ID]);
    XCTAssertNil([log objectForKey:recipe2.ID]);
    
    [cooler markRecipeAsShownWithId:recipe2.ID];
    
    [NSThread sleepForTimeInterval:1.0];
    
    log = [cacheManager loadDictionaryForKey:@"CoolerLogMap"];
    latestLog = [[cacheManager loadNumberForKey:@"CoolerLatestLog"] doubleValue];
    XCTAssertTrue([log count] == 2);
    XCTAssertTrue(latestLog - now.timeIntervalSince1970 > 0.4 && latestLog - now.timeIntervalSince1970 < 1);
    XCTAssertNotNil([log objectForKey:recipe1.ID]);
    XCTAssertNotNil([log objectForKey:recipe2.ID]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation"];
    [cacheManager removeAllItemsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRecipeCoolerCacheNotEmpty {
    NITRecipe *recipe1 = [[NITRecipe alloc] init];
    recipe1.ID = @"recipe1";
    recipe1.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:2.0]};
    
    NITRecipe *recipe2 = [[NITRecipe alloc] init];
    recipe2.ID = @"recipe2";
    recipe2.cooldown = @{@"global_cooldown" : [NSNumber numberWithDouble:1.0], @"self_cooldown" : [NSNumber numberWithDouble:3.0]};
    
    NSArray<NITRecipe*> *recipes = @[recipe1, recipe2];
    
    NITCacheManager *cacheManager = [[NITCacheManager alloc] initWithAppId:@"testRecipeCoolerCacheNotEmpty"];
    NSDate *now = [NSDate date];
    NSDictionary<NSString*, NSNumber*> *cachedLog = @{recipe1.ID : [NSNumber numberWithDouble:now.timeIntervalSince1970], recipe2.ID : [NSNumber numberWithDouble:now.timeIntervalSince1970]};
    NSNumber *cachedLatestLog = [NSNumber numberWithDouble:now.timeIntervalSince1970];
    
    [cacheManager saveWithObject:cachedLog forKey:@"CoolerLogMap"];
    [cacheManager saveWithObject:cachedLatestLog forKey:@"CoolerLatestLog"];
    [NSThread sleepForTimeInterval:0.2];
    
    NITRecipeCooler *cooler = [[NITRecipeCooler alloc] initWithCacheManager:cacheManager];
    NSArray<NITRecipe*> *filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 0);
    
    [NSThread sleepForTimeInterval:1.2];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 0);
    
    [NSThread sleepForTimeInterval:1.0];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 1);
    
    [NSThread sleepForTimeInterval:1.0];
    
    filteredRecipes = [cooler filterRecipeWithRecipes:recipes];
    XCTAssertTrue([filteredRecipes count] == 2);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation"];
    [cacheManager removeAllItemsWithCompletionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)recipesManager:(NITRecipesManager *)recipesManager gotRecipe:(NITRecipe *)recipe {
    if ([self.name containsString:@"testOnlineEvaluation"]) {
        XCTAssertNotNil(recipe);
        [self.expectation fulfill];
    } else if([self.name containsString:@"testOnlinePulseEvaluation"]) {
        XCTAssertNotNil(recipe);
        XCTAssertTrue([recipe.pulseBundle.ID isEqualToString:@"e11f58db-054e-4df1-b09b-d0cbe2676031"]);
        [self.expectation fulfill];
    }
}

@end
