//
//  NITRecipeRepository.m
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITRecipeRepository.h"
#import "NITRecipe.h"
#import "NITCacheManager.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"
#import "NITDateManager.h"
#import "NITTimestampsManager.h"
#import "NITConfiguration.h"
#import "NITRecipeHistory.h"
#import "NITTimestampsManager.h"
#import "NITCoupon.h"
#import "NITClaim.h"
#import "NITImage.h"
#import "NITRecipesApi.h"

NSString* const RecipesCacheKey = @"Recipes";
NSString* const RecipesLastEditedTimeCacheKey = @"RecipesLastEditedTime";
NSString* const RecipePulseOnlineAvailable = @"RecipePulseOnlineAvailable";

@interface NITRecipeRepository()

@property (nonatomic, strong) NSArray<NITRecipe*> *recipes;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITTimestampsManager *timestampsManager;
@property (nonatomic, strong) NITRecipesApi *api;
@property (nonatomic) NSTimeInterval lastEditedTime;
@property (nonatomic) BOOL pulseEvaluationOnline;

@end

@implementation NITRecipeRepository

- (instancetype)initWithCacheManager:(NITCacheManager *)cacheManager dateManager:(NITDateManager *)dateManager configuration:(NITConfiguration *)configuration recipeHistory:(NITRecipeHistory * _Nonnull)recipeHistory timestampsManager:(NITTimestampsManager * _Nonnull)timestampsManager api:(NITRecipesApi * _Nonnull)api {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.dateManager = dateManager;
        self.configuration = configuration;
        self.recipeHistory = recipeHistory;
        self.timestampsManager = timestampsManager;
        self.api = api;
        self.recipes = [self.cacheManager loadArrayForKey:RecipesCacheKey];
        NSNumber *time = [self.cacheManager loadNumberForKey:RecipesLastEditedTimeCacheKey];
        if (time) {
            self.lastEditedTime = (NSTimeInterval)time.doubleValue;
        } else {
            self.lastEditedTime = TimestampInvalidTime;
        }
        NSNumber *online = [self.cacheManager loadNumberForKey:RecipePulseOnlineAvailable];
        if (online) {
            self.pulseEvaluationOnline = [online boolValue];
        } else {
            self.pulseEvaluationOnline = YES;
        }
    }
    return self;
}

- (NSInteger)recipesCount {
    return [self.recipes count];
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.api processRecipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, BOOL pulseOnlineEvaluation, NSError * _Nullable error) {
        if (error) {
            NSArray<NITRecipe*> *cachedRecipes = [self.cacheManager loadArrayForKey:RecipesCacheKey];
            if (cachedRecipes) {
                self.recipes = cachedRecipes;
                if (completionHandler) {
                    completionHandler(nil);
                }
            } else {
                if (completionHandler) {
                    completionHandler(error);
                }
            }
        } else {
            NSDate *today = [self.dateManager currentDate];
            self.lastEditedTime = [today timeIntervalSince1970];
            [self.cacheManager saveWithObject:[NSNumber numberWithDouble:self.lastEditedTime] forKey:RecipesLastEditedTimeCacheKey];
            self.pulseEvaluationOnline = pulseOnlineEvaluation;
            [self.cacheManager saveWithObject:[NSNumber numberWithBool:pulseOnlineEvaluation] forKey:RecipePulseOnlineAvailable];
            self.recipes = recipes;
            [self.cacheManager saveWithObject:self.recipes forKey:RecipesCacheKey];
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
}

- (void)recipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler {
    [self.api processRecipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, BOOL pulseOnlineEvaluation, NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        } else {
            if (completionHandler) {
                completionHandler(recipes, nil);
            }
        }
    }];
}

- (void)syncWithCompletionHandler:(void (^)(NSError * _Nullable, BOOL))completionHandler {
    [self.timestampsManager checkTimestampWithType:@"recipes" referenceTime:self.lastEditedTime completionHandler:^(BOOL needToSync) {
        if (needToSync) {
            [self refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
                if (completionHandler) {
                    completionHandler(error, YES);
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(nil, NO);
            }
        }
    }];
}

- (NSArray<NITRecipe*>*)matchingRecipesWithPulsePlugin:(NSString*)pulsePlugin pulseAction:(NSString *)pulseAction pulseBundle:(NSString *)pulseBundle {
    NSMutableArray<NITRecipe*> *matchingRecipes = [[NSMutableArray alloc] init];
    
    for (NITRecipe *recipe in self.recipes) {
        if ([recipe.pulsePluginId isEqualToString:pulsePlugin] && [recipe.pulseAction.ID isEqualToString:pulseAction] && [recipe.pulseBundle.ID isEqualToString:pulseBundle]) {
            [matchingRecipes addObject:recipe];
        }
    }
    
    return [NSArray arrayWithArray:matchingRecipes];
}

- (NSArray<NITRecipe *> *)matchingRecipesWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction tags:(NSArray<NSString *> *)tags {
    NSMutableArray<NITRecipe*> *matchingRecipes = [[NSMutableArray alloc] init];
    
    for (NITRecipe *recipe in self.recipes) {
        if ([recipe.pulsePluginId isEqualToString:pulsePlugin] && [recipe.pulseAction.ID isEqualToString:pulseAction] && [self verifyTags:tags recipeTags:recipe.tags]) {
            [matchingRecipes addObject:recipe];
        }
    }
    
    return [NSArray arrayWithArray:matchingRecipes];
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

- (BOOL)isPulseOnlineEvaluationAvaialble {
    return self.pulseEvaluationOnline;
}

- (void)addRecipe:(NITRecipe *)recipe {
    NSMutableArray *mutRecipes = [NSMutableArray arrayWithArray:self.recipes];
    [mutRecipes addObject:recipe];
    self.recipes = [NSArray arrayWithArray:mutRecipes];
    [self.cacheManager saveWithObject:self.recipes forKey:RecipesCacheKey];
}

@end
