//
//  NITRecipeRepositoryTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITRecipeRepository.h"
#import "NITRecipesManager.h"
#import "NITCacheManager.h"
#import "NITNetworkMockManger.h"
#import "NITDateManager.h"
#import "NITRecipeHistory.h"
#import "NITEvaluationBodyBuilder.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface NITRecipeRepositoryTest : NITTestCase

@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITNetworkMockManger *networkManager;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;

@end

@implementation NITRecipeRepositoryTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.cacheManager = mock([NITCacheManager class]);
    self.networkManager = [[NITNetworkMockManger alloc] init];
    self.dateManager = mock([NITDateManager class]);
    self.configuration = mock([NITConfiguration class]);
    self.recipeHistory = mock([NITRecipeHistory class]);
    self.evaluationBodyBuilder = mock([NITEvaluationBodyBuilder class]);
    [given([self.evaluationBodyBuilder buildEvaluationBody]) willReturn:[self simpleJsonApi]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// MARK: - Refresh config cache check

- (void)testRecipesManagerCacheNotEmpty {
    NITJSONAPI *jsonApi = [self jsonApiWithContentsOfFile:@"recipes"];
    [jsonApi registerClass:[NITRecipe class] forType:@"recipes"];
    
    NSArray<NITRecipe*> *recipes = [jsonApi parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    self.networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:self.networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *recipesExp = [self expectationWithDescription:@"Recipes"];
    [repository refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([repository recipesCount] == 6);
        [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
        [recipesExp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testRecipesDownloadEmptyCache {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:nil];
    
    self.networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return recipesJson;
    };
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:self.networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [repository recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        XCTAssertTrue(self.networkManager.isMockCalled);
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
    
    self.networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return recipesJson;
    };
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:self.networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [repository recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        XCTAssertTrue(self.networkManager.isMockCalled);
        XCTAssertTrue(recipes.count == 6);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

// MARK: - Timestamps check

- (void)testRecipesCheckTimeEmptyCache {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    NSTimeInterval time = 10000;
    
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [self setNetworkMockForRecipesProcessWithJsonApi:recipesJson networkManager:networkManager];
    [self setNetworkMockForTimestampsWithTime:time networkManager:networkManager];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    [verifyCount(self.cacheManager, times(1)) loadNumberForKey:RecipesLastEditedTimeCacheKey];
    
    [repository refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
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
    [self setNetworkMockForRecipesProcessWithJsonApi:recipesJson networkManager:networkManager];
    [self setNetworkMockForTimestampsWithTime:time networkManager:networkManager];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    
    [repository refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
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
    [self setNetworkMockForRecipesProcessWithJsonApi:recipesJson networkManager:networkManager];
    [self setNetworkMockForTimestampsWithTime:time networkManager:networkManager];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager networkManager:networkManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory evaluationBodyBuilder:self.evaluationBodyBuilder];
    
    [repository refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

// MARK: - Utils

- (void)setNetworkMockForRecipesProcessWithJsonApi:(NITJSONAPI*)jsonApi networkManager:(NITNetworkMockManger*)networkManager {
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/recipes/process"]) {
            return jsonApi;
        }
        return nil;
    } forKey:@"recipes"];
}

- (void)setNetworkMockForTimestampsWithTime:(NSTimeInterval)time networkManager:(NITNetworkMockManger*)networkManager {
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/timestamps"]) {
            return [self makeTimestampsResponseWithTimeInterval:time];
        }
        return nil;
    } forKey:@"timestamps"];
}

@end