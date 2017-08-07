 //
//  NITGeopolisRadar.m
//  NearITSDK
//
//  Created by Francesco Leoni on 04/07/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITGeopolisRadar.h"
#import "NITGeopolisNodesManager.h"
#import "NITLog.h"
#import <CoreLocation/CoreLocation.h>
#import "NITNode.h"
#import "NITGeofenceNode.h"
#import "NITBeaconNode.h"
#import "NITBeaconProximityManager.h"
#import "NITConstants.h"

#define LOGTAG @"GeopolisRadar"
#define MAX_LOCATION_TIMER_RETRY 3
static NSString *const restartLock = @"restartLock";

@interface NITGeopolisRadar()<CLLocationManagerDelegate>

@property (nonatomic, strong) NITGeopolisNodesManager *nodesManager;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NITBeaconProximityManager *beaconProximity;
@property (nonatomic, strong) NSMutableArray<NITNode*> *visitedNodes;
@property (nonatomic, strong) NSTimer *locationTimer;
@property (nonatomic) NSInteger locationTimerRetry;
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL stepResponse;

@end

@implementation NITGeopolisRadar

- (instancetype)initWithDelegate:(id<NITGeopolisRadarDelegate>)delegate nodesManager:(NITGeopolisNodesManager *)nodesManager locationManager:(CLLocationManager *)locationManager beaconProximityManager:(NITBeaconProximityManager * _Nonnull)beaconProximity {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.nodesManager = nodesManager;
        self.locationManager = locationManager;
        self.beaconProximity = beaconProximity;
        self.visitedNodes = [[NSMutableArray alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.delegate = self;
        self.started = NO;
    }
    return self;
}

// MARK: - Start

- (BOOL)start {
    if(self.started) {
        return YES;
    }
    
    NITLogD(LOGTAG, @"Geopolis radar start");
    
    if([[self.nodesManager roots] count] == 0) {
        return NO;
    }
    
    CLAuthorizationStatus authorizationStatus = [self locationAuthorizationStatus];
    if (authorizationStatus != kCLAuthorizationStatusAuthorizedWhenInUse && authorizationStatus != kCLAuthorizationStatusAuthorizedAlways) {
        NITLogE(LOGTAG, @"Geopolis couldn't start radar: CLLocationManager authorizationStatus is wrong");
        return NO;
    }
    self.started = YES;
    
    [self.locationManager requestLocation];
    self.locationTimerRetry = 0;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.locationTimer = [self makeLocationTimer];
    }];
    
    [self startMonitoringRoots];
    
    return YES;
}

- (BOOL)isStarted {
    return self.started;
}

- (BOOL)restart {
    BOOL start = NO;
    @synchronized (restartLock) {
        [self stop];
        start = [self start];
    }
    return start;
}

- (void)startMonitoringRoots {
    NITLogD(LOGTAG, @"Geopolis start monitoring roots");
    NSArray<NITNode*> *roots = [self.nodesManager roots];
    for (NITNode *node in roots) {
        CLRegion *region = [node createRegion];
        [self.locationManager startMonitoringForRegion:region];
        [self.locationManager requestStateForRegion:region];
    }
}

// MARK: - Stop

- (void)stop {
    self.started = NO;
    self.stepResponse = NO;
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    for (CLBeaconRegion *region in self.locationManager.rangedRegions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
    [self.locationManager stopUpdatingLocation];
    [self.nodesManager clear];
    [self.locationTimer invalidate];
    self.locationTimer = nil;
    self.locationTimerRetry = 0;
}

// MARK: - Location timer

- (void)locationTimerFired:(NSTimer*)timer {
    self.locationTimerRetry++;
    NITLogD(@"LocationTimer", @"Entered in timer: retry %d", self.locationTimerRetry);
    if (self.locationTimerRetry >= MAX_LOCATION_TIMER_RETRY) {
        NITLogW(@"LocationTimer", @"MAX_LOCATION_TIMER_RETRY reached");
        [self.locationTimer invalidate];
        self.locationTimer = nil;
    } else if (!self.stepResponse) {
        NITLogW(@"LocationTimer", @"Request step response by timer");
        [self.locationManager requestLocation];
        [self requestStateForRoots];
    } else {
        [self.locationTimer invalidate];
        self.locationTimer = nil;
        NITLogD(@"LocationTimer", @"Invalidate timer due to a successful state");
    }
}

// MARK: - Step

- (void)stepInRegion:(CLRegion*)region {
    self.stepResponse = YES;
    NITLogD(LOGTAG, @"StepInRegion -> %@", region.identifier);
    NITNode *node = [self.nodesManager nodeWithID:region.identifier];
    if (node == nil) {
        return;
    }
    NITLogD(LOGTAG, @"StepInNode -> %@", node);
    if (![self isAlreadyVisitedWithNode:node]) {
        [self triggerInRegion:region];
    }
    
    [self setVisitedWithNode:node];
    NSArray<NITNode*> *monitoredNodes = [self.nodesManager monitoredNodesOnEnterWithId:region.identifier];
    NSArray<NITNode*> *rangedNodes = [self.nodesManager rangedNodesOnEnterWithId:region.identifier];
    NITLogD(LOGTAG, @"Regions state stepIn MR -> %d, RR -> %d", [monitoredNodes count], [rangedNodes count]);
    
    [self setMonitoringWithNodes:monitoredNodes];
    [self setRangingWithNodes:rangedNodes];
}

- (void)triggerInRegion:(CLRegion*)region {
    self.stepResponse = YES;
    NITLogD(LOGTAG, @"TriggerInRegion -> %@", region.identifier);
    NITNode *node = [self.nodesManager nodeWithID:region.identifier];
    if (node == nil) {
        return;
    }
    NITLogD(LOGTAG, @"TriggerInNode -> %@", node);
    
    [self setVisitedWithNode:node];
    if ([node isKindOfClass:[NITGeofenceNode class]]) {
        [self triggerWithEvent:NITRegionEventEnterPlace node:node];
    } else {
        [self triggerWithEvent:NITRegionEventEnterArea node:node];
    }
}

- (void)stepOutRegion:(CLRegion*)region {
    self.stepResponse = YES;
    NITLogD(LOGTAG, @"StepOutRegion -> %@", region.identifier);
    NITNode *node = [self.nodesManager nodeWithID:region.identifier];
    if (node == nil) {
        return;
    }
    NITLogD(LOGTAG, @"StepOutNode -> %@", node);
    
    BOOL isMonitored = NO;
    for (CLRegion *monitoredRegion in self.locationManager.monitoredRegions) {
        if ([monitoredRegion.identifier isEqualToString:region.identifier]) {
            isMonitored = YES;
        }
    }
    
    if (!isMonitored) {
        NITLogD(LOGTAG, @"StepOutNode ignored because is not monitored -> %@", node);
        return;
    }
    
    NSArray<NITNode*> *monitoredNodes = [self.nodesManager monitoredNodesOnExitWithId:region.identifier];
    NSArray<NITNode*> *rangedNodes = [self.nodesManager rangedNodesOnExitWithId:region.identifier];
    NITLogD(LOGTAG, @"Regions state stepOut MR -> %d, RR -> %d", [monitoredNodes count], [rangedNodes count]);
    
    [self setMonitoringWithNodes:monitoredNodes];
    [self setRangingWithNodes:rangedNodes];
}

- (void)triggerOutRegion:(CLRegion*)region {
    self.stepResponse = YES;
    NITLogD(LOGTAG, @"TriggerOutRegion -> %@", region.identifier);
    NITNode *node = [self.nodesManager nodeWithID:region.identifier];
    if (node == nil) {
        return;
    }
    NITLogD(LOGTAG, @"TriggerOutNode -> %@", node);
    
    if ([node isKindOfClass:[NITGeofenceNode class]]) {
        [self triggerWithEvent:NITRegionEventLeavePlace node:node];
    } else {
        [self triggerWithEvent:NITRegionEventLeaveArea node:node];
    }
}

- (BOOL)stillExistsWithRegionIdentifier:(NSString*)identifier nodes:(NSArray<NITNode*>*)nodes {
    BOOL exists = NO;
    for(NITNode *node in nodes) {
        if ([node.ID.lowercaseString isEqualToString:identifier.lowercaseString]) {
            exists = YES;
            break;
        }
    }
    return exists;
}

- (BOOL)existsWithRegionIdentifier:(NSString*)identifier regions:(NSArray<CLRegion*>*)regions {
    BOOL exists = NO;
    for (CLRegion *region in regions) {
        if ([region.identifier.lowercaseString isEqualToString:identifier.lowercaseString]) {
            exists = YES;
            break;
        }
    }
    return exists;
}

- (void)setMonitoringWithNodes:(NSArray<NITNode*>*)nodes {
    for(CLRegion *region in self.locationManager.monitoredRegions) {
        if (![self stillExistsWithRegionIdentifier:region.identifier nodes:nodes]) {
            [self.locationManager stopMonitoringForRegion:region];
            NITNode *node = [self.nodesManager nodeWithID:region.identifier];
            if (node) {
                [self setNotVisitedWithNode:node];
            }
        }
    }
    
    for(NITNode *node in nodes) {
        if (![self existsWithRegionIdentifier:node.ID regions:[self.locationManager.monitoredRegions allObjects]]) {
            CLRegion *region = [node createRegion];
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            [self.locationManager startMonitoringForRegion:region];
            [self.locationManager requestStateForRegion:region];
        }
    }
}

- (void)setRangingWithNodes:(NSArray<NITNode*>*)nodes {
    for(CLBeaconRegion *region in self.locationManager.rangedRegions) {
        if (![self stillExistsWithRegionIdentifier:region.identifier nodes:nodes]) {
            [self.locationManager stopRangingBeaconsInRegion:region];
            [self.beaconProximity removeRegionWithIdentifier:region.identifier];
            NITNode *node = [self.nodesManager nodeWithID:region.identifier];
            if (node) {
                [self setNotVisitedWithNode:node];
            }
        }
    }
    
    for(NITNode *node in nodes) {
        if (![self existsWithRegionIdentifier:node.ID regions:[self.locationManager.rangedRegions allObjects]]) {
            CLRegion *region = [node createRegion];
            if ([region isKindOfClass:[CLBeaconRegion class]]) {
                [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
                [self.beaconProximity addRegionWithIdentifier:region.identifier];
            }
        }
    }
}

- (void)setVisitedWithNode:(NITNode*)node {
    [self.visitedNodes addObject:node];
}

- (void)setNotVisitedWithNode:(NITNode*)node {
    [self.visitedNodes removeObject:node];
}

- (BOOL)isAlreadyVisitedWithNode:(NITNode*)node {
    NSUInteger index = [self.visitedNodes indexOfObject:node];
    if (index != NSNotFound) {
        return YES;
    }
    return NO;
}

- (void)requestStateForRoots {
    NSArray<NITNode*> *roots = [self.nodesManager roots];
    for (NITNode *node in roots) {
        CLRegion *region = [node createRegion];
        [self.locationManager requestStateForRegion:region];
    }
}

// MARK: - Trigger

- (void)triggerWithEvent:(NITRegionEvent)event node:(NITNode*)node {
    if ([self.delegate respondsToSelector:@selector(geopolisRadar:didTriggerWithNode:event:)]) {
        [self.delegate geopolisRadar:self didTriggerWithNode:node event:event];
    }
}

// MARK: - Utils

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return [CLLocationManager authorizationStatus];
}

- (NSTimer*)makeLocationTimer {
    return [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(locationTimerFired:) userInfo:nil repeats:YES];
}

- (NITRegionEvent)regionEventFromProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityImmediate:
            return NITRegionEventImmediate;
        case CLProximityNear:
            return NITRegionEventNear;
        case CLProximityFar:
            return NITRegionEventFar;
        default:
            return NITRegionEventUnknown;
    }
}

// MARK: - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    switch (state) {
        case CLRegionStateInside:
            [self stepInRegion:region];
            break;
        case CLRegionStateOutside:
            [self stepOutRegion:region];
            break;
        case CLRegionStateUnknown:
            NITLogE(LOGTAG, @"Undefined status for region in node: %@", [self.nodesManager nodeWithID:region.identifier]);
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self triggerInRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self triggerOutRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NITNode *node = [self.nodesManager nodeWithID:region.identifier];
    NITBeaconNode *beaconNode;
    if ([node isKindOfClass:[NITBeaconNode class]]) {
        beaconNode = (NITBeaconNode*)node;
    } else {
        return;
    }
    
    NSMutableArray<NSString*>* appeared = [[NSMutableArray alloc] init];
    
    for(CLBeacon *beacon in beacons) {
        CLProximity proximity = beacon.proximity;
        
        if (proximity == CLProximityUnknown) {
            continue;
        }
        
        NITBeaconNode *minorNode = [self.nodesManager beaconNodeWithBeacon:beacon inChildren:beaconNode.children];
        NITRegionEvent beaconEvent = [self regionEventFromProximity:proximity];
        NSString *beaconIdentifier = minorNode.identifier;
        
        if (minorNode != nil && beaconIdentifier != nil) {
            [appeared addObject:beaconIdentifier];
            
            CLProximity previousProximity = [self.beaconProximity proximityWithBeaconIdentifier:beaconIdentifier regionIdentifier:region.identifier];
            if (previousProximity != proximity) {
                [self.beaconProximity addProximityWithBeaconIdentifier:beaconIdentifier regionIdentifier:region.identifier proximity:beacon.proximity];
                if (proximity != CLProximityFar) {
                    [self triggerWithEvent:beaconEvent node:minorNode];
                }
            }
        }
    }
    
    [self.beaconProximity evaluateDisappearedWithBeaconIdentifiers:appeared regionIdentifier:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    NITLogD(LOGTAG, @"Location update (%.4f,%.4f) %.1f seconds ago", location.coordinate.latitude, location.coordinate.longitude, fabs(howRecent));
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

@end
