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
#import <CoreLocation/CoreLocation.h>

#define LOGTAG @"GeopolisManager"
#define MAX_LOCATION_TIMER_RETRY 3

NSErrorDomain const NITGeopolisErrorDomain = @"com.nearit.geopolis";
NSString* const NodeKey = @"node";
NSString* const NodeJSONCacheKey = @"GeopolisNodesJSON";

@interface NITGeopolisManager()<CLLocationManagerDelegate, NITGeopolisRadarDelegate>

@property (nonatomic, strong) NITGeopolisNodesManager *nodesManager;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) id<NITNetworkManaging> networkManaeger;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) NITBeaconProximityManager *beaconProximity;
@property (nonatomic, strong) NITNode *currentNode;
@property (nonatomic, strong) NSString *pluginName;
@property (nonatomic, strong) NITNetworkProvider *provider;
@property (nonatomic, strong) NITGeopolisRadar *radar;

@end

@implementation NITGeopolisManager

- (instancetype)initWithNodesManager:(NITGeopolisNodesManager*)nodesManager cachaManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration*)configuration trackManager:(NITTrackManager *)trackManager {
    self = [super init];
    if (self) {
        self.nodesManager = nodesManager;
        self.cacheManager = cacheManager;
        self.networkManaeger = networkManager;
        self.trackManager = trackManager;
        self.configuration = configuration;
        self.pluginName = @"geopolis";
        self.beaconProximity = [[NITBeaconProximityManager alloc] init];
        
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        self.radar = [[NITGeopolisRadar alloc] initWithDelegate:self nodesManager:self.nodesManager locationManager:locationManager beaconProximityManager:self.beaconProximity];
    }
    return self;
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    [self.networkManaeger makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] geopolisNodes] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            NITJSONAPI *jsonApi = [self.cacheManager loadObjectForKey:NodeJSONCacheKey];
            if (jsonApi) {
                [self.nodesManager setNodesWithJsonApi:jsonApi];
                completionHandler(nil);
            } else {
                completionHandler(error);
            }
        } else {
            [self.nodesManager setNodesWithJsonApi:json];
            [self.cacheManager saveWithObject:json forKey:NodeJSONCacheKey];
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
    
    BOOL hasIdentifier = NO;
    BOOL hasTags = NO;
    NSString *pulseAction = [NITUtils stringFromRegionEvent:event];
    
    if([self.recipesManager respondsToSelector:@selector(gotPulseWithPulsePlugin:pulseAction:pulseBundle:)]) {
        hasIdentifier = [self.recipesManager gotPulseWithPulsePlugin:self.pluginName pulseAction:pulseAction pulseBundle:node.identifier];
    }
    if (!hasIdentifier && [self.recipesManager respondsToSelector:@selector(gotPulseWithPulsePlugin:pulseAction:tags:)]) {
        NSString *pulseTagAction = [NITUtils stringTagFromRegionEvent:event];
        hasTags = [self.recipesManager gotPulseWithPulsePlugin:self.pluginName pulseAction:pulseTagAction tags:node.tags];
    }
    if (!hasIdentifier && !hasTags && [self.recipesManager respondsToSelector:@selector(gotPulseOnlineWithPulsePlugin:pulseAction:pulseBundle:)]) {
        [self.recipesManager gotPulseOnlineWithPulsePlugin:self.pluginName pulseAction:pulseAction pulseBundle:node.identifier];
    }
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
