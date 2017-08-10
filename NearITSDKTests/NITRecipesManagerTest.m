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
#import "NITConfiguration.h"
#import "NITReachability.h"
#import "NITRecipeHistory.h"
#import "NITRecipeValidationFilter.h"
#import "NITPulseBundle.h"
#import "NITRecipeRepository.h"
#import "NITRecipeTrackSender.h"
#import "NITTriggerRequest.h"
#import "NITRecipesApi.h"
#import "NITTriggerRequestQueue.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

typedef void (^SingleRecipeBlock) (NITRecipe*, NSError*);

@interface NITRecipesManager (Tests)

- (BOOL)gotPulseWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction pulseBundle:(NSString *)pulseBundle;
- (BOOL)gotPulseWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction tags:(NSArray<NSString *> *)tags;
- (void)gotPulseOnlineWithTriggerRequest:(NITTriggerRequest*)request;
- (void)evaluateRecipeWithId:(NSString*)recipeId;

@end

@interface NITRecipesManagerTest : NITTestCase

@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) NITReachability *reachability;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITRecipeRepository *repository;
@property (nonatomic, strong) NITRecipeTrackSender *trackSender;
@property (nonatomic, strong) NITRecipesApi *api;
@property (nonatomic, strong) NITTriggerRequestQueue *requestQueue;

@end

@implementation NITRecipesManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.reachability = mock([NITReachability class]);
    [given([self.reachability currentReachabilityStatus]) willReturnInteger:NotReachable];
    self.recipeHistory = mock([NITRecipeHistory class]);
    self.recipeValidationFilter = mock([NITRecipeValidationFilter class]);
    self.repository = mock([NITRecipeRepository class]);
    self.trackSender = mock([NITRecipeTrackSender class]);
    self.api = mock([NITRecipesApi class]);
    self.requestQueue = mock([NITTriggerRequestQueue class]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOnlineEvaluation {
    id<NITManaging> managing = mockProtocol(@protocol(NITManaging));
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithRecipeValidationFilter:self.recipeValidationFilter repository:self.repository trackSender:self.trackSender api:self.api requestQueue:self.requestQueue];
    [given([self.repository recipes]) willReturn:[self recipesFromJsonWithName:@"online_recipe"]];
    recipesManager.manager = managing;
    
    NITRecipe *recipe = [[NITRecipe alloc] init];
    recipe.ID = @"recipeId";
    [givenVoid([self.api evaluateRecipeWithId:recipe.ID completionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        SingleRecipeBlock block = [invocation mkt_arguments][1];
        block(recipe, nil);
        return nil;
    }];
    
    NITTriggerRequest *request = [[NITTriggerRequest alloc] init];
    request.pulsePlugin = @"geopolis";
    request.pulseAction = @"leave_place";
    request.pulseBundle = @"9712e11a-ef3a-4b34-bdf6-413a84146f2e";
    
    [recipesManager evaluateRecipeWithId:recipe.ID];
    [verifyCount(managing, times(1)) recipesManager:anything() gotRecipe:sameInstance(recipe)];
}

- (void)testOnlinePulseEvaluation {
    id<NITManaging> managing = mockProtocol(@protocol(NITManaging));
    
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithRecipeValidationFilter:self.recipeValidationFilter repository:self.repository trackSender:self.trackSender api:self.api requestQueue:self.requestQueue];
    [given([self.repository recipes]) willReturn:[self recipesFromJsonWithName:@"online_recipe"]];
    recipesManager.manager = managing;
    
    NITRecipe *recipe = [[NITRecipe alloc] init];
    [givenVoid([self.api onlinePulseEvaluationWithPlugin:anything() action:anything() bundle:anything() completionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        SingleRecipeBlock block = [invocation mkt_arguments][3];
        block(recipe, nil);
        return nil;
    }];
    [given(self.repository.isPulseOnlineEvaluationAvaialble) willReturnBool:YES];
    
    NITTriggerRequest *request = [[NITTriggerRequest alloc] init];
    request.pulsePlugin = @"beacon_forest";
    request.pulseAction = @"always_evaluated";
    request.pulseBundle = @"e11f58db-054e-4df1-b09b-d0cbe2676031";
    
    [recipesManager gotPulseOnlineWithTriggerRequest:request];
    [verifyCount(managing, times(1)) recipesManager:anything() gotRecipe:sameInstance(recipe)];
}

- (void)testGotPulseBundleNoMatching {
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithRecipeValidationFilter:self.recipeValidationFilter repository:self.repository trackSender:self.trackSender api:self.api requestQueue:self.requestQueue];
    [given([self.repository recipes]) willReturn:[self recipesFromJsonWithName:@"recipes"]];
    
    networkManager.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    
    NITRecipe *fakeRecipe = [[NITRecipe alloc] init];
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:@[fakeRecipe]];
    
    BOOL hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"enter_place" pulseBundle:@"average_bundle"];
    XCTAssertFalse(hasIdentifier);
}

- (void)testGotPulseBundleMatchingWithValidation {
    NITRecipesManager *recipesManager = [[NITRecipesManager alloc] initWithRecipeValidationFilter:self.recipeValidationFilter repository:self.repository trackSender:self.trackSender api:self.api requestQueue:self.requestQueue];
    [given([self.repository recipes]) willReturn:[self recipesFromJsonWithName:@"recipes"]];
    
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:nil];
    NITRecipe *recipe = [self makeRecipeWithPulsePlugin:@"geopolis" pulseAction:@"ranging.near" pulseBundle:@"8373e68b-7c5d-411c-9a9c-3cc7ebf039e4" tags:nil];
    [given([self.repository matchingRecipesWithPulsePlugin:anything() pulseAction:anything() pulseBundle:anything()]) willReturn:@[recipe]];
    
    // Has matching but the validation has empty recipes
    BOOL hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"ranging.near" pulseBundle:@"8373e68b-7c5d-411c-9a9c-3cc7ebf039e4"];
    XCTAssertFalse(hasIdentifier);
    
    NITRecipe *fakeRecipe = [[NITRecipe alloc] init];
    [given([self.recipeValidationFilter filterRecipes:anything()]) willReturn:@[fakeRecipe]];
    
    // Has matching and the validation has at least one recipes
    hasIdentifier = [recipesManager gotPulseWithPulsePlugin:@"geopolis" pulseAction:@"ranging.near" pulseBundle:@"8373e68b-7c5d-411c-9a9c-3cc7ebf039e4"];
    XCTAssertTrue(hasIdentifier);
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

// MARK: - Utils

- (NSArray<NITRecipe*> *)recipesFromJsonWithName:(NSString*)name {
    NITJSONAPI *recipesJson = [self jsonApiWithContentsOfFile:@"online_recipe"];
    [recipesJson registerClass:[NITRecipe class] forType:@"recipes"];
    NSArray<NITRecipe*> *recipes = [recipesJson parseToArrayOfObjects];
    return recipes;
}

@end
