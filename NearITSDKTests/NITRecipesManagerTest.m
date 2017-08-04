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
#import "NITRecipeCooler.h"
#import "NITCacheManager.h"
#import "NITNetworkManager.h"
#import "NITNetworkMockManger.h"
#import "NITConfiguration.h"
#import "NITReachability.h"
#import "NITTrackManager.h"
#import "NITDateManager.h"
#import "NITRecipeHistory.h"
#import "NITRecipeValidationFilter.h"
#import "NITPulseBundle.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface NITRecipesManagerTest : NITTestCase<NITManaging>

@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) NITReachability *reachability;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITTrackManager *trackManager;

@end

@implementation NITRecipesManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.reachability = mock([NITReachability class]);
    [given([self.reachability currentReachabilityStatus]) willReturnInteger:NotReachable];
    self.dateManager = [[NITDateManager alloc] init];
    NITCacheManager *cacheManager = mock([NITCacheManager class]);
    self.recipeHistory = [[NITRecipeHistory alloc] initWithCacheManager:cacheManager dateManager:self.dateManager];
    self.recipeValidationFilter = mock([NITRecipeValidationFilter class]);
    self.cacheManager = mock([NITCacheManager class]);
    self.trackManager = mock([NITTrackManager class]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOnlineEvaluation {
    self.expectation = [self expectationWithDescription:@"expectation"];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:nil];
    
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"online_recipe"];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    recipesManager.manager = self;
    
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return [self jsonApiWithContentsOfFile:@"response_online_recipe"];
    };
    
    [recipesManager gotPulseOnlineWithPulsePlugin:@"geopolis" pulseAction:@"leave_place" pulseBundle:@"9712e11a-ef3a-4b34-bdf6-413a84146f2e"];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testOnlinePulseEvaluation {
    self.expectation = [self expectationWithDescription:@"expectation"];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:nil];
    
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"online_recipe"];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    recipesManager.manager = self;
    
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return [self jsonApiWithContentsOfFile:@"response_pulse_evaluation"];
    };
    
    [recipesManager gotPulseOnlineWithPulsePlugin:@"beacon_forest" pulseAction:@"always_evaluated" pulseBundle:@"e11f58db-054e-4df1-b09b-d0cbe2676031"];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testGotPulseBundleNoMatching {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    
    NITRecipe *fakeRecipe = [[NITRecipe alloc] init];
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:@[fakeRecipe]];
    
    BOOL hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"enter_place" pulseBundle:@"average_bundle"];
    XCTAssertFalse(hasIdentifier);
}

- (void)testGotPulseBundleMatchingWithValidation {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [recipesManager setRecipesWithJsonApi:recipesJson];
    
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:nil];
    
    // Has matching but the validation has empty recipes
    BOOL hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"ranging.near" pulseBundle:@"8373e68b-7c5d-411c-9a9c-3cc7ebf039e4"];
    XCTAssertFalse(hasIdentifier);
    
    NITRecipe *fakeRecipe = [[NITRecipe alloc] init];
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:@[fakeRecipe]];
    
    // Has matching and the validation has at least one recipes
    hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"ranging.near" pulseBundle:@"8373e68b-7c5d-411c-9a9c-3cc7ebf039e4"];
    XCTAssertTrue(hasIdentifier);
}

- (void)testRecipesManagerCacheNotEmpty {
    NITJSONAPI *jsonApi = [self jsonApiWithContentsOfFile:@"recipes"];
    [jsonApi registerClass:[NITRecipe class] forType:@"recipes"];
    
    NSArray<NITRecipe*> *recipes = [jsonApi parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *recipesExp = [self expectationWithDescription:@"Recipes"];
    [recipesManager refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([recipesManager recipesCount] == 6);
        [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
        [recipesExp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testRecipesDownloadEmptyCache {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:nil];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return recipesJson;
    };
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [recipesManager recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        XCTAssertTrue(networkManager.isMockCalled);
        XCTAssertTrue(recipes.count == 6);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testRecipesDownloadFilledCache {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [recipesJson registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*> *recipes = [recipesJson parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return recipesJson;
    };
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [recipesManager recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        XCTAssertTrue(networkManager.isMockCalled);
        XCTAssertTrue(recipes.count == 6);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

// MARK: - Timestamp recipes refresh

- (void)testRecipesCheckTimeEmptyCache {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    NSTimeInterval time = 10000;
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/recipes/process"]) {
            return recipesJson;
        }
        return nil;
    } forKey:@"recipes"];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/timestamps"]) {
            return [self makeTimestampsResponseWithTimeInterval:time];
        }
        return nil;
    } forKey:@"timestamps"];
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    [verifyCount(self.cacheManager, times(1)) loadNumberForKey:RecipesLastEditedTimeCacheKey];
    
    [recipesManager refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

- (void)testRecipesCheckTimeCacheIsUpdated {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [recipesJson registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*> *recipes = [recipesJson parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    NSTimeInterval time = 10000;
    [given([self.cacheManager loadNumberForKey:RecipesLastEditedTimeCacheKey]) willReturn:[NSNumber numberWithDouble:time + 10]];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/recipes/process"]) {
            return recipesJson;
        }
        return nil;
    } forKey:@"recipes"];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/timestamps"]) {
            return [self makeTimestampsResponseWithTimeInterval:time];
        }
        return nil;
    } forKey:@"timestamps"];
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    
    [recipesManager refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, never()) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, never()) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

- (void)testRecipesCheckTimeCacheIsOld {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [recipesJson registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*> *recipes = [recipesJson parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    NSTimeInterval time = 10000;
    [given([self.cacheManager loadNumberForKey:RecipesLastEditedTimeCacheKey]) willReturn:[NSNumber numberWithDouble:time - 10]];
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/recipes/process"]) {
            return recipesJson;
        }
        return nil;
    } forKey:@"recipes"];
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/timestamps"]) {
            return [self makeTimestampsResponseWithTimeInterval:time];
        }
        return nil;
    } forKey:@"timestamps"];
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithCacheManager:self.cacheManager networkManager:networkManager configuration:[[NITConfiguration alloc] init] trackManager:self.trackManager recipeHistory:self.recipeHistory recipeValidationFilter:self.recipeValidationFilter dateManager:self.dateManager];
    
    [recipesManager refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

// MARK: - Tags loading

- (void)testLoadingRecipesWithPulseBundleTags {
    NITJSONAPI *json = [self jsonApiWithContentsOfFile:@"recipe_pulse_bundle_tags"];
    [json registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*> *recipes = [json parseToArrayOfObjects];
    XCTAssertTrue(recipes.count == 1);
    if (recipes.count > 0) {
        NITRecipe *recipe = [recipes objectAtIndex:0];
        XCTAssertTrue(recipe.tags.count == 3);
        for(NSInteger index = 0; index < recipe.tags.count; index++) {
            NSString *tag = [recipe.tags objectAtIndex:index];
            switch (index) {
                case 0:
                    XCTAssertTrue([tag isEqualToString:@"banana"]);
                    break;
                case 1:
                    XCTAssertTrue([tag isEqualToString:@"apple"]);
                    break;
                case 2:
                    XCTAssertTrue([tag isEqualToString:@"hello world"]);
                    break;
                    
                default:
                    break;
            }
        }
    }
}

// MARK: - NITManaging delegate

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
