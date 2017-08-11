//
//  NITRecipesManager.m
//  NearITSDK
//
//  Created by Francesco Leoni on 20/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITRecipesManager.h"
#import "NITJSONAPI.h"
#import "NITRecipe.h"
#import "NITJSONAPIResource.h"
#import "NITCoupon.h"
#import "NITConstants.h"
#import "NITImage.h"
#import "NITClaim.h"
#import "NITRecipeValidationFilter.h"
#import "NITTimestampsManager.h"
#import "NITRecipeRepository.h"
#import "NITRecipeTrackSender.h"
#import "NITTriggerRequest.h"
#import "NITRecipesApi.h"
#import "NITTriggerRequestQueue.h"
#import "NITTrackingInfo.h"

#define LOGTAG @"RecipesManager"

@interface NITRecipesManager()<NITTriggerRequestQueueDelegate>

@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITRecipeRepository *repository;
@property (nonatomic, strong) NITRecipeTrackSender *trackSender;
@property (nonatomic, strong) NITRecipesApi *api;
@property (nonatomic, strong) NITTriggerRequestQueue *requestQueue;

@end

@implementation NITRecipesManager

- (instancetype)initWithRecipeValidationFilter:(NITRecipeValidationFilter * _Nonnull)recipeValidationFilter repository:(NITRecipeRepository * _Nonnull)repository trackSender:(NITRecipeTrackSender * _Nonnull)trackSender api:(NITRecipesApi * _Nonnull)api requestQueue:(NITTriggerRequestQueue * _Nonnull)requestQueue {
    self = [super init];
    if (self) {
        self.recipeValidationFilter = recipeValidationFilter;
        self.repository = repository;
        self.trackSender = trackSender;
        self.api = api;
        self.requestQueue = requestQueue;
        self.requestQueue.delegate = self;
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
    [self.repository syncWithCompletionHandler:^(NSError * _Nullable error, BOOL isUpdated) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

// MARK: - NITRecipesManaging

- (BOOL)gotPulseLocalWithTriggerRequest:(NITTriggerRequest*)request {
    BOOL handled = NO;
    
    NSArray<NITRecipe*>* matchingRecipes = [self.repository matchingRecipesWithPulsePlugin:request.pulsePlugin pulseAction:request.pulseAction pulseBundle:request.pulseBundle];
    
    if (matchingRecipes.count > 0) {
        handled = YES;
    }
    
    handled &= [self handleRecipesValidation:matchingRecipes triggerRequest:request];
    
    return handled;
}

- (BOOL)gotPulseTagsWithTriggerRequest:(NITTriggerRequest*)request {
    BOOL handled = NO;
    
    NSArray<NITRecipe*>* matchingRecipes = [self.repository matchingRecipesWithPulsePlugin:request.pulsePlugin pulseAction:request.tagAction tags:request.tags];
    
    if (matchingRecipes.count > 0) {
        handled = YES;
    }
    
    handled &= [self handleRecipesValidation:matchingRecipes triggerRequest:request];
    
    return handled;
}

- (void)gotPulseOnlineWithTriggerRequest:(NITTriggerRequest*)request {
    if (self.repository.isPulseOnlineEvaluationAvaialble) {
        [self onlinePulseEvaluationWithTriggerRequest:request];
    } else {
        [self.requestQueue addRequest:request];
    }
}

- (void)gotTriggerRequest:(NITTriggerRequest *)request {
    BOOL handledPulseLocal = [self gotPulseLocalWithTriggerRequest:request];
    if (!handledPulseLocal) {
        BOOL handledTags = [self gotPulseTagsWithTriggerRequest:request];
        if (!handledTags) {
            [self gotPulseOnlineWithTriggerRequest:request];
        }
    }
}

- (void)gotTriggerRequestReevaluation:(NITTriggerRequest *)request {
    BOOL handledPulseLocal = [self gotPulseLocalWithTriggerRequest:request];
    if (!handledPulseLocal) {
        BOOL handledTags = [self gotPulseTagsWithTriggerRequest:request];
        if (!handledTags && self.repository.isPulseOnlineEvaluationAvaialble) {
            [self onlinePulseEvaluationWithTriggerRequest:request];
        }
    }
}

- (BOOL)handleRecipesValidation:(NSArray<NITRecipe*>*)matchingRecipes triggerRequest:(NITTriggerRequest*)request {
    NSArray<NITRecipe*> *recipes = [self.recipeValidationFilter filterRecipes:matchingRecipes];
    
    if ([recipes count] == 0) {
        return NO;
    } else {
        NITRecipe *recipe = [recipes objectAtIndex:0];
        if(recipe.isEvaluatedOnline) {
            [self evaluateRecipeWithId:recipe.ID trackingInfo:request.trackingInfo];
        } else {
            [self gotRecipe:recipe trackingInfo:request.trackingInfo];
        }
    }
    
    return YES;
}

- (void)processRecipe:(NSString*)recipeId {
    [self processRecipe:recipeId completion:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe trackingInfo:[NITTrackingInfo trackingInfoFromRecipeId:recipe.ID]];
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

- (void)onlinePulseEvaluationWithTriggerRequest:(NITTriggerRequest *)request {
    [self.api onlinePulseEvaluationWithPlugin:request.pulsePlugin action:request.pulseAction bundle:request.pulseBundle completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe trackingInfo:request.trackingInfo];
        }
    }];
}

- (void)evaluateRecipeWithId:(NSString*)recipeId trackingInfo:(NITTrackingInfo*)trackingInfo {
    [self.api evaluateRecipeWithId:recipeId completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            [self gotRecipe:recipe trackingInfo:trackingInfo];
        }
    }];
}

- (void)sendTrackingWithTrackingInfo:(NITTrackingInfo *)trackingInfo event:(NSString *)event {
    [self.trackSender sendTrackingWithTrackingInfo:trackingInfo event:event];
}

- (void)gotRecipe:(NITRecipe*)recipe trackingInfo:(NITTrackingInfo*)trackingInfo {
    NITLogD(LOGTAG, @"Got a recipe: %@", recipe.ID);
    if (trackingInfo) {
        trackingInfo.recipeId = recipe.ID;
    }
    if ([self.manager respondsToSelector:@selector(recipesManager:gotRecipe:trackingInfo:)]) {
        [self.manager recipesManager:self gotRecipe:recipe trackingInfo:trackingInfo];
    }
}

- (NSInteger)recipesCount {
    return [self.repository.recipes count];
}

// MARK - Trigger request queue delegate

- (void)triggerRequestQueue:(NITTriggerRequestQueue *)queue didFinishWithRequest:(NITTriggerRequest *)request {
    [self gotTriggerRequestReevaluation:request];
}

@end
