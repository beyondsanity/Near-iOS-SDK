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
#import "NITCoupon.h"
#import "NITConstants.h"
#import "NITImage.h"
#import "NITClaim.h"
#import "NITCacheManager.h"
#import "NITRecipeValidationFilter.h"
#import "NITTimestampsManager.h"
#import "NITRecipeRepository.h"
#import "NITRecipeTrackSender.h"
#import "NITEvaluationBodyBuilder.h"
#import "NITTriggerRequest.h"
#import "NITRecipesApi.h"

#define LOGTAG @"RecipesManager"

@interface NITRecipesManager()

@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITRecipeRepository *repository;
@property (nonatomic, strong) NITRecipeTrackSender *trackSender;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;
@property (nonatomic, strong) NITRecipesApi *api;

@end

@implementation NITRecipesManager

- (instancetype)initWithCacheManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager recipeValidationFilter:(NITRecipeValidationFilter * _Nonnull)recipeValidationFilter repository:(NITRecipeRepository * _Nonnull)repository trackSender:(NITRecipeTrackSender * _Nonnull)trackSender evaluationBodyBuilder:(NITEvaluationBodyBuilder *)evaluationBodyBuilder api:(NITRecipesApi * _Nonnull)api {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.recipeValidationFilter = recipeValidationFilter;
        self.repository = repository;
        self.trackSender = trackSender;
        self.evaluationBodyBuilder = evaluationBodyBuilder;
        self.api = api;
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

- (void)gotPulseOnlineWithTriggerRequest:(NITTriggerRequest*)request {
    [self onlinePulseEvaluationWithPlugin:request.pulsePlugin action:request.pulseAction bundle:request.pulseBundle];
}

- (void)gotTriggerRequest:(NITTriggerRequest *)request {
    BOOL handledPulseLocal = [self gotPulseWithPulsePlugin:request.pulsePlugin pulseAction:request.pulseAction pulseBundle:request.pulseBundle];
    if (!handledPulseLocal) {
        BOOL handledTags = [self gotPulseWithPulsePlugin:request.pulsePlugin pulseAction:request.tagAction tags:request.tags];
        if (!handledTags) {
            [self gotPulseOnlineWithTriggerRequest:request];
        }
    }
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
    [self.api fetchRecipeWithId:recipeId completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        } else {
            if (completionHandler) {
                completionHandler(recipe, error);
            }
        }
    }];
}

- (void)onlinePulseEvaluationWithPlugin:(NSString*)plugin action:(NSString*)action bundle:(NSString*)bundle {
    [self.api onlinePulseEvaluationWithPlugin:plugin action:action bundle:bundle completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe];
        }
    }];
}

- (void)evaluateRecipeWithId:(NSString*)recipeId {
    [self.api evaluateRecipeWithId:recipeId completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe];
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

- (NSInteger)recipesCount {
    return [self.repository.recipes count];
}

@end
