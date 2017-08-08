//
//  NITRecipesManager.m
//  NearITSDK
//
//  Created by Francesco Leoni on 20/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITRecipesManager.h"
#import "NITNetworkProvider.h"
#import "NITJSONAPI.h"
#import "NITRecipe.h"
#import "NITJSONAPIResource.h"
#import "NITConfiguration.h"
#import "NITCoupon.h"
#import "NITConstants.h"
#import "NITImage.h"
#import "NITClaim.h"
#import "NITCacheManager.h"
#import "NITRecipeHistory.h"
#import "NITRecipeValidationFilter.h"
#import "NITTimestampsManager.h"
#import "NITRecipeRepository.h"
#import "NITRecipeTrackSender.h"
#import "NITEvaluationBodyBuilder.h"

#define LOGTAG @"RecipesManager"

@interface NITRecipesManager()

@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITRecipeRepository *repository;
@property (nonatomic, strong) NITRecipeTrackSender *trackSender;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;

@end

@implementation NITRecipesManager

- (instancetype)initWithCacheManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration *)configuration recipeHistory:(NITRecipeHistory * _Nonnull)recipeHistory recipeValidationFilter:(NITRecipeValidationFilter * _Nonnull)recipeValidationFilter repository:(NITRecipeRepository * _Nonnull)repository trackSender:(NITRecipeTrackSender * _Nonnull)trackSender evaluationBodyBuilder:(NITEvaluationBodyBuilder *)evaluationBodyBuilder {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.configuration = configuration;
        self.recipeHistory = recipeHistory;
        self.recipeValidationFilter = recipeValidationFilter;
        self.repository = repository;
        self.trackSender = trackSender;
        self.evaluationBodyBuilder = evaluationBodyBuilder;
    }
    return self;
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.repository refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)recipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler {
    [self.repository recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(recipes, error);
        }
    }];
}

- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.repository refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

// MARK: - NITRecipesManaging

- (BOOL)gotPulseWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction pulseBundle:(NSString *)pulseBundle {
    BOOL handled = NO;
    NSMutableArray<NITRecipe*> *matchingRecipes = [[NSMutableArray alloc] init];
    
    for (NITRecipe *recipe in self.repository.recipes) {
        if ([recipe.pulsePluginId isEqualToString:pulsePlugin] && [recipe.pulseAction.ID isEqualToString:pulseAction] && [recipe.pulseBundle.ID isEqualToString:pulseBundle]) {
            [matchingRecipes addObject:recipe];
        }
    }
    
    if (matchingRecipes.count > 0) {
        handled = YES;
    }
    
    handled &= [self handleRecipesValidation:matchingRecipes];
    
    return handled;
}

- (BOOL)gotPulseWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction tags:(NSArray<NSString *> *)tags {
    BOOL handled = NO;
    NSMutableArray<NITRecipe*> *matchingRecipes = [[NSMutableArray alloc] init];
    
    for (NITRecipe *recipe in self.repository.recipes) {
        if ([recipe.pulsePluginId isEqualToString:pulsePlugin] && [recipe.pulseAction.ID isEqualToString:pulseAction] && [self verifyTags:tags recipeTags:recipe.tags]) {
            [matchingRecipes addObject:recipe];
        }
    }
    
    if (matchingRecipes.count > 0) {
        handled = YES;
    }
    
    handled &= [self handleRecipesValidation:matchingRecipes];
    
    return handled;
}

- (void)gotPulseOnlineWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction pulseBundle:(NSString *)pulseBundle {
    [self onlinePulseEvaluationWithPlugin:pulsePlugin action:pulseAction bundle:pulseBundle];
}

- (BOOL)handleRecipesValidation:(NSArray<NITRecipe*>*)matchingRecipes {
    NSArray<NITRecipe*> *recipes = [self.recipeValidationFilter filterRecipes:matchingRecipes];
    
    if ([recipes count] == 0) {
        return NO;
    } else {
        NITRecipe *recipe = [recipes objectAtIndex:0];
        if(recipe.isEvaluatedOnline) {
            [self evaluateRecipeWithId:recipe.ID];
        } else {
            [self gotRecipe:recipe];
        }
    }
    
    return YES;
}

- (BOOL)verifyTags:(NSArray<NSString*>*)tags recipeTags:(NSArray<NSString*>*)recipeTags {
    if (tags == nil || recipeTags == nil) {
        return NO;
    }
    
    NSInteger trueCount = 0;
    for(NSString *tag in tags) {
        if ([recipeTags indexOfObjectIdenticalTo:tag] != NSNotFound) {
            trueCount++;
        }
    }
    if (trueCount == recipeTags.count) {
        return YES;
    }
    return NO;
}

- (void)processRecipe:(NSString*)recipeId {
    [self processRecipe:recipeId completion:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe];
        }
    }];
}

- (void)processRecipe:(NSString*)recipeId completion:(void (^_Nullable)(NITRecipe * _Nullable recipe, NSError * _Nullable error))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] processRecipeWithId:recipeId] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (json) {
            [self registerClassesWithJsonApi:json];
            NSArray<NITRecipe*> *recipes = [json parseToArrayOfObjects];
            if ([recipes count] > 0) {
                NITRecipe *recipe = [recipes objectAtIndex:0];
                if (completionHandler) {
                    completionHandler(recipe, nil);
                    return;
                }
            }
        }
        NSError *anError = [NSError errorWithDomain:NITRecipeErrorDomain code:151 userInfo:@{NSLocalizedDescriptionKey:@"Invalid recipe data", NSUnderlyingErrorKey: error}];
        completionHandler(nil, anError);
    }];
}

- (void)onlinePulseEvaluationWithPlugin:(NSString*)plugin action:(NSString*)action bundle:(NSString*)bundle {
    NITJSONAPI *jsonApi = [self.evaluationBodyBuilder buildEvaluationBodyWithPlugin:plugin action:action bundle:bundle];
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] onlinePulseEvaluationWithJsonApi:jsonApi] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (json) {
            [self registerClassesWithJsonApi:json];
            NSArray<NITRecipe*> *recipes = [json parseToArrayOfObjects];
            if ([recipes count] > 0) {
                NITRecipe *recipe = [recipes objectAtIndex:0];
                [self gotRecipe:recipe];
            }
        }
    }];
}

- (void)evaluateRecipeWithId:(NSString*)recipeId {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] evaluateRecipeWithId:recipeId jsonApi:[self.evaluationBodyBuilder buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (json) {
            [self registerClassesWithJsonApi:json];
            NSArray<NITRecipe*> *recipes = [json parseToArrayOfObjects];
            if([recipes count] > 0) {
                NITRecipe *recipe = [recipes objectAtIndex:0];
                [self gotRecipe:recipe];
            }
        }
    }];
}

- (void)sendTrackingWithRecipeId:(NSString *)recipeId event:(NSString*)event {
    [self.trackSender sendTrackingWithRecipeId:recipeId event:event];
}

- (void)gotRecipe:(NITRecipe*)recipe {
    NITLogD(LOGTAG, @"Got a recipe: %@", recipe.ID);
    if ([self.manager respondsToSelector:@selector(recipesManager:gotRecipe:)]) {
        [self.manager recipesManager:self gotRecipe:recipe];
    }
}

- (void)registerClassesWithJsonApi:(NITJSONAPI*)jsonApi {
    [jsonApi registerClass:[NITRecipe class] forType:@"recipes"];
    [jsonApi registerClass:[NITCoupon class] forType:@"coupons"];
    [jsonApi registerClass:[NITClaim class] forType:@"claims"];
    [jsonApi registerClass:[NITImage class] forType:@"images"];
}

- (NSInteger)recipesCount {
    return [self.repository.recipes count];
}

@end
