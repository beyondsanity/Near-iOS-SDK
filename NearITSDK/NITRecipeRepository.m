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
#import "NITNetworkProvider.h"
#import "NITTimestampsManager.h"
#import "NITConfiguration.h"
#import "NITRecipeHistory.h"
#import "NITEvaluationBodyBuilder.h"

NSString* const RecipesCacheKey = @"Recipes";
NSString* const RecipesLastEditedTimeCacheKey = @"RecipesLastEditedTime";
NSString* const RecipePulseOnlineAvailable = @"RecipePulseOnlineAvailable";

@interface NITRecipeRepository()

@property (nonatomic, strong) NSArray<NITRecipe*> *recipes;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;
@property (nonatomic) NSTimeInterval lastEditedTime;
@property (nonatomic) BOOL pulseEvaluationOnline;

@end

@implementation NITRecipeRepository

- (instancetype)initWithCacheManager:(NITCacheManager *)cacheManager networkManager:(id<NITNetworkManaging>)networkManager dateManager:(NITDateManager *)dateManager configuration:(NITConfiguration *)configuration recipeHistory:(NITRecipeHistory * _Nonnull)recipeHistory evaluationBodyBuilder:(NITEvaluationBodyBuilder * _Nonnull)evaluationBodyBuilder {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.dateManager = dateManager;
        self.configuration = configuration;
        self.recipeHistory = recipeHistory;
        self.evaluationBodyBuilder = evaluationBodyBuilder;
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

- (void)setRecipesWithJsonApi:(NITJSONAPI*)json {
    [json registerClass:[NITRecipe class] forType:@"recipes"];
    self.recipes = [json parseToArrayOfObjects];
}

- (NSInteger)recipesCount {
    return [self.recipes count];
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self.evaluationBodyBuilder buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
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
            [json registerClass:[NITRecipe class] forType:@"recipes"];
            id onlineEvaluation = [json metaForKey:@"online_evaluation"];
            if (onlineEvaluation && [onlineEvaluation isKindOfClass:[NSNumber class]]) {
                self.pulseEvaluationOnline = [onlineEvaluation boolValue];
                [self.cacheManager saveWithObject:onlineEvaluation forKey:RecipePulseOnlineAvailable];
            }
            self.recipes = [json parseToArrayOfObjects];
            [self.cacheManager saveWithObject:self.recipes forKey:RecipesCacheKey];
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
}

- (void)recipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self.evaluationBodyBuilder buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        } else {
            if (completionHandler) {
                [json registerClass:[NITRecipe class] forType:@"recipes"];
                NSArray<NITRecipe*>* recipes = [json parseToArrayOfObjects];
                completionHandler(recipes, nil);
            }
        }
    }];
}

- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] timestamps] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            [self refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
                completionHandler(error);
            }];
        } else {
            NITTimestampsManager *timestampsManager = [[NITTimestampsManager alloc] initWithJsonApi:json];
            if ([timestampsManager needsToUpdateForType:@"recipes" referenceTime:self.lastEditedTime]) {
                [self refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
                    completionHandler(error);
                }];
            } else {
                completionHandler(nil);
            }
        }
    }];
}

- (BOOL)isPulseOnlineEvaluationAvaialble {
    return self.pulseEvaluationOnline;
}

@end
