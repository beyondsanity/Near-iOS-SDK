//
//  NITEvaluationBodyBuilder.m
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITEvaluationBodyBuilder.h"
#import "NITConfiguration.h"
#import "NITRecipeHistory.h"
#import "NITDateManager.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"

@interface NITEvaluationBodyBuilder()

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *recipeHistory;
@property (nonatomic, strong) NITDateManager *dateManager;

@end

@implementation NITEvaluationBodyBuilder

- (instancetype)initWithConfiguration:(NITConfiguration *)configuration recipeHistory:(NITRecipeHistory *)recipeHistory dateManager:(NITDateManager *)dateManager {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.recipeHistory = recipeHistory;
        self.dateManager = dateManager;
    }
    return self;
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
