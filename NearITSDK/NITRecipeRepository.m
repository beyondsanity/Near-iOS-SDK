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

NSString* const RecipesCacheKey = @"Recipes";
NSString* const RecipesLastEditedTimeCacheKey = @"RecipesLastEditedTime";

@interface NITRecipeRepository()

@property (nonatomic, strong) NSArray<NITRecipe*> *recipes;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic) NSTimeInterval lastEditedTime;

@end

@implementation NITRecipeRepository

- (instancetype)initWithCacheManager:(NITCacheManager *)cacheManager networkManager:(id<NITNetworkManaging>)networkManager dateManager:(NITDateManager *)dateManager configuration:(NITConfiguration *)configuration recipeHistory:(NITRecipeHistory * _Nonnull)recipeHistory {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.dateManager = dateManager;
        self.configuration = configuration;
        self.recipeHistory = recipeHistory;
        self.recipes = [self.cacheManager loadArrayForKey:RecipesCacheKey];
        NSNumber *time = [self.cacheManager loadNumberForKey:RecipesLastEditedTimeCacheKey];
        if (time) {
            self.lastEditedTime = (NSTimeInterval)time.doubleValue;
        } else {
            self.lastEditedTime = TimestampInvalidTime;
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
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
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
            self.recipes = [json parseToArrayOfObjects];
            [self.cacheManager saveWithObject:self.recipes forKey:RecipesCacheKey];
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
}

- (void)recipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
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

// MARK: - Evaluation body

- (NITJSONAPI*)buildEvaluationBody {
    return [self buildEvaluationBodyWithPlugin:nil action:nil bundle:nil];
}

- (NITJSONAPI*)buildEvaluationBodyWithPlugin:(NSString*)plugin action:(NSString*)action bundle:(NSString*)bundle {
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"evaluation";
    [resource addAttributeObject:[self buildCoreObject] forKey:@"core"];
    if(plugin) {
        [resource addAttributeObject:plugin forKey:@"pulse_plugin_id"];
    }
    if(action) {
        [resource addAttributeObject:action forKey:@"pulse_action_id"];
    }
    if(bundle) {
        [resource addAttributeObject:bundle forKey:@"pulse_bundle_id"];
    }
    [jsonApi setDataWithResourceObject:resource];
    return jsonApi;
}

- (NSDictionary*)buildCoreObject {
    NITConfiguration *config = self.configuration;
    NSMutableDictionary<NSString*, id> *core = [[NSMutableDictionary alloc] init];
    if (config.appId && config.profileId && config.installationId) {
        [core setObject:config.profileId forKey:@"profile_id"];
        [core setObject:config.installationId forKey:@"installation_id"];
        [core setObject:config.appId forKey:@"app_id"];
        NSDate *now = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"XXX"];
        NSString *hours = [dateFormatter stringFromDate:now];
        [core setObject:hours forKey:@"utc_offset"];
    }
    if (self.recipeHistory) {
        [core setObject:[self buildCooldownBlockWithRecipeCooler:self.recipeHistory] forKey:@"cooldown"];
    }
    return [NSDictionary dictionaryWithDictionary:core];
}

- (NSDictionary*)buildCooldownBlockWithRecipeCooler:(NITRecipeHistory*)recipeHistory {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSNumber *latestLog = [recipeHistory latestLog];
    if (latestLog) {
        [dict setObject:latestLog forKey:@"last_notified_at"];
    }
    NSDictionary<NSString*, NSNumber*> *log = [recipeHistory log];
    if (log) {
        [dict setObject:log forKey:@"recipes_notified_at"];
    }
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
