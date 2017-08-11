//
//  NITRecipeTrackSender.m
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITRecipeTrackSender.h"
#import "NITConfiguration.h"
#import "NITRecipeHistory.h"
#import "NITTrackManager.h"
#import "NITDateManager.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"
#import "NITLog.h"
#import "NITRecipe.h"
#import "NITConstants.h"
#import "NITNetworkProvider.h"
#import "NITTrackingInfo.h"

#define LOGTAG @"RecipeTrackSender"

@interface NITRecipeTrackSender()

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITRecipeHistory *history;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) NITDateManager *dateManager;

@end

@implementation NITRecipeTrackSender

- (instancetype)initWithConfiguration:(NITConfiguration *)configuration history:(NITRecipeHistory *)history trackManager:(NITTrackManager *)trackManager dateManager:(NITDateManager *)dateManager {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.history = history;
        self.trackManager = trackManager;
        self.dateManager = dateManager;
    }
    return self;
}

- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event {
    if ([event isEqualToString:NITRecipeNotified]) {
        [self.history markRecipeAsShownWithId:recipeId];
    }
    
    NITJSONAPI *jsonApi = [self buildTrackingBodyWithRecipeId:recipeId event:event];
    if (jsonApi) {
        [self.trackManager addTrackWithRequest:[[NITNetworkProvider sharedInstance] sendTrackingsWithJsonApi:jsonApi]];
    }
}

- (void)sendTrackingWithTrackingInfo:(NITTrackingInfo *)trackingInfo event:(NSString *)event {
    if (trackingInfo == nil || trackingInfo.recipeId == nil || event == nil) {
        return;
    }
    
    if ([event isEqualToString:NITRecipeNotified]) {
        [self.history markRecipeAsShownWithId:trackingInfo.recipeId];
    }
    
    NITJSONAPI *jsonApi = [self buildTrackingBodyWithTrackingInfo:trackingInfo event:event];
    if (jsonApi) {
        [self.trackManager addTrackWithRequest:[[NITNetworkProvider sharedInstance] sendTrackingsWithJsonApi:jsonApi]];
    }
}

- (NITJSONAPI*)buildTrackingBodyWithRecipeId:(NSString*)recipeId event:(NSString*)event {
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"trackings";
    if (self.configuration.profileId && self.configuration.installationId && self.configuration.appId) {
        [resource addAttributeObject:self.configuration.profileId forKey:@"profile_id"];
        [resource addAttributeObject:self.configuration.installationId forKey:@"installation_id"];
        [resource addAttributeObject:self.configuration.appId forKey:@"app_id"];
    } else {
        NITLogW(LOGTAG, @"Can't send geopolis tracking: missing data");
        return nil;
    }
    [resource addAttributeObject:recipeId forKey:@"recipe_id"];
    [resource addAttributeObject:event forKey:@"event"];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = ISO8601DateFormatMilliseconds;
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [resource addAttributeObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"tracked_at"];
    
    [jsonApi setDataWithResourceObject:resource];
    
    return jsonApi;
}

- (NITJSONAPI*)buildTrackingBodyWithTrackingInfo:(NITTrackingInfo*)trackingInfo event:(NSString*)event {
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"trackings";
    if (self.configuration.profileId && self.configuration.installationId && self.configuration.appId) {
        [resource addAttributeObject:self.configuration.profileId forKey:@"profile_id"];
        [resource addAttributeObject:self.configuration.installationId forKey:@"installation_id"];
        [resource addAttributeObject:self.configuration.appId forKey:@"app_id"];
    } else {
        NITLogW(LOGTAG, @"Can't send geopolis tracking: missing data");
        return nil;
    }
    [resource addAttributeObject:trackingInfo.recipeId forKey:@"recipe_id"];
    [resource addAttributeObject:event forKey:@"event"];
    [resource addAttributeObject:[trackingInfo extrasDictionary] forKey:@"metadata"];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = ISO8601DateFormatMilliseconds;
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [resource addAttributeObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"tracked_at"];
    
    [jsonApi setDataWithResourceObject:resource];
    
    return jsonApi;
}

@end
