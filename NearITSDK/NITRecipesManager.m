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
#import "NITTrackManager.h"
#import "NITDateManager.h"
#import "NITRecipeHistory.h"
#import "NITRecipeValidationFilter.h"
#import "NITTimestampsManager.h"

#define LOGTAG @"RecipesManager"
NSString* const RecipesCacheKey = @"Recipes";
NSString* const RecipesLastEditedTimeCacheKey = @"RecipesLastEditedTime";

@interface NITRecipesManager()

@property (nonatomic, strong) NSArray<NITRecipe*> *recipes;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITRecipeValidationFilter *recipeValidationFilter;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NSNumber *lastEditedTime;

@end

@implementation NITRecipesManager

- (instancetype)initWithCacheManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration *)configuration trackManager:(NITTrackManager * _Nonnull)trackManager recipeHistory:(NITRecipeHistory * _Nonnull)recipeHistory recipeValidationFilter:(NITRecipeValidationFilter * _Nonnull)recipeValidationFilter dateManager:(NITDateManager * _Nonnull)dateManager {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.configuration = configuration;
        self.trackManager = trackManager;
        self.recipeHistory = recipeHistory;
        self.recipeValidationFilter = recipeValidationFilter;
        self.dateManager = dateManager;
        self.recipes = [self.cacheManager loadArrayForKey:RecipesCacheKey];
        self.lastEditedTime = [self.cacheManager loadNumberForKey:RecipesLastEditedTimeCacheKey];
    }
    return self;
}

- (void)setRecipesWithJsonApi:(NITJSONAPI*)json {
    [json registerClass:[NITRecipe class] forType:@"recipes"];
    self.recipes = [json parseToArrayOfObjects];
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        [self refreshRecipesWithJson:json error:error completion:^(NSError * _Nullable cError) {
            if (completionHandler) {
                completionHandler(cError);
            }
        }];
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
            NSTimeInterval recipesTime = [timestampsManager timeForType:@"recipes"];
            if (self.lastEditedTime == nil || recipesTime == TimestampInvalidTime || (recipesTime != TimestampInvalidTime && recipesTime > self.lastEditedTime.doubleValue)) {
                [self refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
                    completionHandler(error);
                }];
            } else {
                completionHandler(nil);
            }
        }
    }];
}

- (void)refreshRecipesWithJson:(NITJSONAPI*)json error:(NSError*)error completion:(void (^_Nullable)(NSError * _Nullable error))completionHandler {
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
        self.lastEditedTime = [NSNumber numberWithDouble:[today timeIntervalSince1970]];
        [self.cacheManager saveWithObject:self.lastEditedTime forKey:RecipesLastEditedTimeCacheKey];
        [json registerClass:[NITRecipe class] forType:@"recipes"];
        self.recipes = [json parseToArrayOfObjects];
        [self.cacheManager saveWithObject:self.recipes forKey:RecipesCacheKey];
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}

// MARK: - NITRecipesManaging

- (BOOL)gotPulseWithPulsePlugin:(NSString *)pulsePlugin pulseAction:(NSString *)pulseAction pulseBundle:(NSString *)pulseBundle {
    BOOL handled = NO;
    NSMutableArray<NITRecipe*> *matchingRecipes = [[NSMutableArray alloc] init];
    
    for (NITRecipe *recipe in self.recipes) {
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
    
    for (NITRecipe *recipe in self.recipes) {
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
    NITJSONAPI *jsonApi = [self buildEvaluationBodyWithPlugin:plugin action:action bundle:bundle];
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
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] evaluateRecipeWithId:recipeId jsonApi:[self buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
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
    if ([event isEqualToString:NITRecipeNotified]) {
        [self.recipeHistory markRecipeAsShownWithId:recipeId];
    }
    
    NITConfiguration *config = self.configuration;
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"trackings";
    if (self.configuration.profileId && self.configuration.installationId && self.configuration.appId) {
        [resource addAttributeObject:config.profileId forKey:@"profile_id"];
        [resource addAttributeObject:config.installationId forKey:@"installation_id"];
        [resource addAttributeObject:config.appId forKey:@"app_id"];
    } else {
        NITLogW(LOGTAG, @"Can't send geopolis tracking: missing data");
        return;
    }
    [resource addAttributeObject:recipeId forKey:@"recipe_id"];
    [resource addAttributeObject:event forKey:@"event"];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = ISO8601DateFormatMilliseconds;
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [resource addAttributeObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"tracked_at"];
    
    [jsonApi setDataWithResourceObject:resource];
    
    [self.trackManager addTrackWithRequest:[[NITNetworkProvider sharedInstance] sendTrackingsWithJsonApi:jsonApi]];
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
    return [self.recipes count];
}

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
