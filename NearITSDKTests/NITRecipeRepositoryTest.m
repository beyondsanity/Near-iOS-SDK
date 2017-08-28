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
#import "NITTimestampsManager.h"
#import "NITRecipesApi.h"
#import "NITResource.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

typedef void (^TimestampsCheckBlock)(BOOL needToSync);
typedef void (^ProcessRecipesBlock)(NSArray<NITRecipe*>*, BOOL, NSError*);

@interface NITRecipeRepository (Tests)

- (void)setRecipes:(NSArray<NITRecipe *> *)recipes;
- (BOOL)verifyTags:(NSArray<NSString*>*)tags recipeTags:(NSArray<NSString*>*)recipeTags;

@end

@interface NITRecipeRepositoryTest : NITTestCase

@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITTimestampsManager *timestampsManager;
@property (nonatomic, strong) NITRecipesApi *recipesApi;

@end

@implementation NITRecipeRepositoryTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.cacheManager = mock([NITCacheManager class]);
    self.dateManager = mock([NITDateManager class]);
    self.configuration = mock([NITConfiguration class]);
    self.recipeHistory = mock([NITRecipeHistory class]);
    self.timestampsManager = mock([NITTimestampsManager class]);
    self.recipesApi = mock([NITRecipesApi class]);
    
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"recipes"];
    [recipesJson registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*>* recipes = [recipesJson parseToArrayOfObjects];
    [givenVoid([self.recipesApi processRecipesWithCompletionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        ProcessRecipesBlock block = [invocation mkt_arguments][0];
        block(recipes, NO, nil);
        return nil;
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// MARK: - Refresh config cache check

- (void)testRecipesManagerCacheNotEmpty {
    NITJSONAPI *jsonApi = [self jsonApiWithContentsOfFile:@"recipes"];
    [jsonApi registerClass:[NITRecipe class] forType:@"recipes"];
    NITRecipesApi *api = mock([NITRecipesApi class]);
    [givenVoid([api processRecipesWithCompletionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        ProcessRecipesBlock block = [invocation mkt_arguments][0];
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
        block(nil, NO, error);
        return nil;
    }];
    
    NSArray<NITRecipe*> *recipes = [jsonApi parseToArrayOfObjects];
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:recipes];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:api];
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
    [given([self.cacheManager loadArrayForKey:RecipesCacheKey]) willReturn:nil];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [repository recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
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
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Recipes"];
    [repository recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        XCTAssertTrue(recipes.count == 6);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

// MARK: - Timestamps check

- (void)testRecipesCheckTimeNeedToSync {
    [givenVoid([self.timestampsManager checkTimestampWithType:anything() referenceTime:TimestampInvalidTime completionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        TimestampsCheckBlock block = [invocation mkt_arguments][2];
        block(YES);
        return nil;
    }];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    [verifyCount(self.cacheManager, times(1)) loadNumberForKey:RecipesLastEditedTimeCacheKey];
    
    [repository syncWithCompletionHandler:^(NSError * _Nullable error, BOOL isUpdated) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

- (void)testRecipesCheckTimeDontNeedToSync {
    [givenVoid([self.timestampsManager checkTimestampWithType:anything() referenceTime:TimestampInvalidTime completionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        TimestampsCheckBlock block = [invocation mkt_arguments][2];
        block(NO);
        return nil;
    }];
    
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    [verifyCount(self.cacheManager, times(1)) loadArrayForKey:RecipesCacheKey];
    [verifyCount(self.cacheManager, times(1)) loadNumberForKey:RecipesLastEditedTimeCacheKey];
    
    [repository syncWithCompletionHandler:^(NSError * _Nullable error, BOOL isUpdated) {
        XCTAssertNil(error);
        [verifyCount(self.cacheManager, never()) saveWithObject:anything() forKey:RecipesCacheKey];
        [verifyCount(self.cacheManager, never()) saveWithObject:anything() forKey:RecipesLastEditedTimeCacheKey];
    }];
}

// MARK: - Matchings

- (void)testMatchingWithPulseBundle {
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    
    NITRecipe *recipe1 = [self makeRecipeWithPulsePlugin:@"plugin1" pulseAction:@"action1" pulseBundle:@"bundle1" tags:nil];
    NITRecipe *recipe2 = [self makeRecipeWithPulsePlugin:@"plugin2" pulseAction:@"action2" pulseBundle:@"bundle2" tags:nil];
    repository.recipes = @[recipe1, recipe2];
    
    NSArray<NITRecipe*>* matchingRecipes = [repository matchingRecipesWithPulsePlugin:recipe1.pulsePluginId pulseAction:recipe1.pulseAction.ID pulseBundle:recipe1.pulseBundle.ID];
    XCTAssertTrue(matchingRecipes.count == 1);
    
    matchingRecipes = [repository matchingRecipesWithPulsePlugin:@"plugin1" pulseAction:@"action2" pulseBundle:@"bundle1"];
    XCTAssertTrue(matchingRecipes.count == 0);
}

- (void)testMatchingWithTags {
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    
    NITRecipe *recipe1 = [self makeRecipeWithPulsePlugin:@"plugin1" pulseAction:@"action1" pulseBundle:@"bundle1" tags:@[@"tagA", @"tagB"]];
    NITRecipe *recipe2 = [self makeRecipeWithPulsePlugin:@"plugin2" pulseAction:@"action2" pulseBundle:@"bundle2" tags:@[@"tagA"]];
    repository.recipes = @[recipe1, recipe2];
    
    NSArray<NITRecipe*>* matchingRecipes = [repository matchingRecipesWithPulsePlugin:recipe1.pulsePluginId pulseAction:recipe1.pulseAction.ID tags:recipe1.tags];
    XCTAssertTrue(matchingRecipes.count == 1);
    
    matchingRecipes = [repository matchingRecipesWithPulsePlugin:recipe2.pulsePluginId pulseAction:recipe2.pulseAction.ID tags:recipe1.tags];
    XCTAssertTrue(matchingRecipes.count == 1);
    
    matchingRecipes = [repository matchingRecipesWithPulsePlugin:recipe1.pulsePluginId pulseAction:recipe1.pulseAction.ID tags:@[@"tagA"]];
    XCTAssertTrue(matchingRecipes.count == 0);
}

- (void)testVerifyTags {
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    
    XCTAssertFalse([repository verifyTags:nil recipeTags:@[@"tag1"]]);
    XCTAssertFalse([repository verifyTags:@[@"tag1"] recipeTags:nil]);
    XCTAssertFalse([repository verifyTags:nil recipeTags:nil]);
    
    BOOL check = [repository verifyTags:@[@"tag1", @"tag2"] recipeTags:@[@"tag1", @"tag2", @"tag3"]];
    XCTAssertFalse(check);
    check = [repository verifyTags:@[@"tag1", @"tag2", @"tag3"] recipeTags:@[@"tag1", @"tag2"]];
    XCTAssertTrue(check);
    check = [repository verifyTags:@[@"tag1", @"tag3"] recipeTags:@[@"tag1", @"tag2"]];
    XCTAssertFalse(check);
}

- (void)testAddRecipe {
    NITRecipeRepository *repository = [[NITRecipeRepository alloc] initWithCacheManager:self.cacheManager dateManager:self.dateManager configuration:self.configuration recipeHistory:self.recipeHistory timestampsManager:self.timestampsManager api:self.recipesApi];
    
    XCTAssertTrue(repository.recipesCount == 0);
    
    NITRecipe *aRecipe = [[NITRecipe alloc] init];
    aRecipe.ID = @"recipeId";
    [repository addRecipe:aRecipe];
    
    XCTAssertTrue(repository.recipesCount == 1);
    [verifyCount(self.cacheManager, times(1)) saveWithObject:anything() forKey:RecipesCacheKey];
}

@end
