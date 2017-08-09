//
//  NITGeopolisManager.m
//  NearITSDK
//
//  Created by Francesco Leoni on 15/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITGeopolisManager.h"
#import "NITNodesManager.h"
#import "NITNetworkManager.h"
#import "NITNetworkProvider.h"
#import "NITJSONAPI.h"
#import "NITNode.h"
#import "NITBeaconNode.h"
#import "NITGeofenceNode.h"
#import "NITBeaconProximityManager.h"
#import "NITUtils.h"
#import "NITCacheManager.h"
#import "NITJSONAPIResource.h"
#import "NITConfiguration.h"
#import "NITLog.h"
#import "NITGeopolisNodesManager.h"
#import "NITTrackManager.h"
#import "NITGeopolisRadar.h"
#import "NITTimestampsManager.h"
#import "NITDateManager.h"
#import "NITTriggerRequest.h"
#import "NITTimestampsManager.h"
#import <CoreLocation/CoreLocation.h>

#define LOGTAG @"GeopolisManager"
#define MAX_LOCATION_TIMER_RETRY 3

NSErrorDomain const NITGeopolisErrorDomain = @"com.nearit.geopolis";
NSString* const NodeKey = @"node";
NSString* const NodeJSONCacheKey = @"GeopolisNodesJSON";
NSString* const NodeLastEditedTimeCacheKey = @"GeopolisNodesLastEditedTime";

@interface NITGeopolisManager()<CLLocationManagerDelegate, NITGeopolisRadarDelegate>

@property (nonatomic, strong) NITGeopolisNodesManager *nodesManager;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) NITBeaconProximityManager *beaconProximity;
@property (nonatomic, strong) NITNode *currentNode;
@property (nonatomic, strong) NSString *pluginName;
@property (nonatomic, strong) NITNetworkProvider *provider;
@property (nonatomic, strong) NITGeopolisRadar *radar;
@property (nonatomic, strong) NITDateManager *dateManager;
@property (nonatomic, strong) NITTimestampsManager *timestampsManager;
@property (nonatomic) NSTimeInterval lastEditedTime;

@end

@implementation NITGeopolisManager

- (instancetype)initWithNodesManager:(NITGeopolisNodesManager*)nodesManager cachaManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration*)configuration trackManager:(NITTrackManager *)trackManager dateManager:(NITDateManager * _Nonnull)dateManager timestampsManager:(NITTimestampsManager * _Nonnull)timestampsManager {
    self = [super init];
    if (self) {
        self.nodesManager = nodesManager;
        self.cacheManager = cacheManager;
        self.networkManager = networkManager;
        self.trackManager = trackManager;
        self.configuration = configuration;
        self.dateManager = dateManager;
        self.timestampsManager = timestampsManager;
        self.pluginName = @"geopolis";
        self.beaconProximity = [[NITBeaconProximityManager alloc] init];
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        self.radar = [[NITGeopolisRadar alloc] initWithDelegate:self nodesManager:self.nodesManager locationManager:locationManager beaconProximityManager:self.beaconProximity];
        
        NITJSONAPI *jsonApi = [self.cacheManager loadObjectForKey:NodeJSONCacheKey];
        if (jsonApi) {
            [self.nodesManager setNodesWithJsonApi:jsonApi];
        }
        
        NSNumber *time = [self.cacheManager loadNumberForKey:NodeLastEditedTimeCacheKey];
        if (time) {
            self.lastEditedTime = (NSTimeInterval)time.doubleValue;
        } else {
            self.lastEditedTime = TimestampInvalidTime;
        }
    }
    return self;
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] geopolisNodes] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            NITJSONAPI *jsonApi = [self.cacheManager loadObjectForKey:NodeJSONCacheKey];
            if (jsonApi) {
                [self.nodesManager setNodesWithJsonApi:jsonApi];
                completionHandler(nil);
            } else {
                completionHandler(error);
            }
        } else {
            NSDate *today = [self.dateManager currentDate];
            self.lastEditedTime = [today timeIntervalSince1970];
            [self.cacheManager saveWithObject:[NSNumber numberWithDouble:self.lastEditedTime] forKey:NodeLastEditedTimeCacheKey];
            [self.nodesManager setNodesWithJsonApi:json];
            [self.cacheManager saveWithObject:json forKey:NodeJSONCacheKey];
            completionHandler(nil);
        }
    }];
}

- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    [self.timestampsManager checkTimestampWithType:@"geopolis" referenceTime:self.lastEditedTime completionHandler:^(BOOL needToSync) {
        if (needToSync) {
            [self refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
                if (completionHandler) {
                    completionHandler(error);
                }
            }];
        } else {
            completionHandler(nil);
        }
    }];
}

- (BOOL)start {
    return [self.radar start];
}

- (void)stop {
    [self.radar stop];
}

- (BOOL)restart {
    return [self.radar restart];
}

- (BOOL)hasCurrentNode {
    if (self.currentNode) {
        return YES;
    }
    return NO;
}

// MARK: - Trigger

- (void)triggerWithEvent:(NITRegionEvent)event node:(NITNode*)node {
    if (node == nil || node.identifier == nil) {
        return;
    }
    
    NSString *eventString = [NITUtils stringFromRegionEvent:event];
    NITLogD(LOGTAG, @"Trigger for event -> %@ - node -> %@", eventString, node);
    
    [self trackEventWithIdentifier:node.identifier event:event];
    
    NSString *pulseAction = [NITUtils stringFromRegionEvent:event];
    NSString *tagAction = [NITUtils stringTagFromRegionEvent:event];
    
    NITTriggerRequest *request = [[NITTriggerRequest alloc] init];
    request.pulseAction = pulseAction;
    request.pulsePlugin = self.pluginName;
    request.pulseBundle = node.identifier;
    request.tagAction = tagAction;
    request.tags = node.tags;
    
    [self.recipesManager gotTriggerRequest:request];
}

- (void)trackEventWithIdentifier:(NSString*)identifier event:(NITRegionEvent)event {
    NITJSONAPI *json = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"trackings";
    if (self.configuration.profileId && self.configuration.installationId && self.configuration.appId) {
        [resource addAttributeObject:self.configuration.profileId forKey:@"profile_id"];
        [resource addAttributeObject:self.configuration.installationId forKey:@"installation_id"];
        [resource addAttributeObject:self.configuration.appId forKey:@"app_id"];
    } else {
        NITLogW(LOGTAG, @"Can't send recipe tracking: missing data");
        return;
    }
    [resource addAttributeObject:identifier forKey:@"identifier"];
    NSString *eventString = [NITUtils stringFromRegionEvent:event];
    [resource addAttributeObject:eventString forKey:@"event"];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = ISO8601DateFormatMilliseconds;
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [resource addAttributeObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"tracked_at"];
    
    [json setDataWithResourceObject:resource];
    
    [self.trackManager addTrackWithRequest:[[NITNetworkProvider sharedInstance] sendGeopolisTrackingsWithJsonApi:json]];
}

// MARK: - Utils

- (NSArray *)nodes {
    return [self.nodesManager nodes];
}

// MARK: - Radar delegate

- (void)geopolisRadar:(NITGeopolisRadar *)geopolisRadar didTriggerWithNode:(NITNode *)node event:(NITRegionEvent)event {
    [self triggerWithEvent:event node:node];
}

@end
