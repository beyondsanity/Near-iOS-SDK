//
//  NITBeaconNode.m
//  NearITSDK
//
//  Created by Francesco Leoni on 17/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITBeaconNode.h"
#import <CoreLocation/CoreLocation.h>

@implementation NITBeaconNode

- (NSDictionary *)attributesMap {
    return @{@"proximity_uuid" : @"proximityUUID"};
}

- (CLRegion *)createRegion {
    NSInteger depth = 1 + (self.major == nil ? 0 : 1) + (self.minor == nil ? 0 : 1);
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:self.proximityUUID];
    switch (depth) {
        case 1:
            return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:self.ID];
        case 2:
            return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[self.major unsignedIntegerValue] identifier:self.ID];
        case 3:
            return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[self.major unsignedIntegerValue] minor:[self.minor unsignedIntegerValue] identifier:self.ID];
        default:
            return nil;
    }
}

- (NSString *)description {
    if (self.proximityUUID && self.major && self.minor) {
        return [NSString stringWithFormat:@"Node (Beacon) ID: %@ - ProxID: %@ - Major: %@ - Minor: %@", self.ID, self.proximityUUID, self.major, self.minor];
    } else if(self.proximityUUID && self.major) {
        return [NSString stringWithFormat:@"Node (Beacon) ID: %@ - ProxID: %@ - Major: %@", self.ID, self.proximityUUID, self.major];
    } else if(self.proximityUUID) {
        return [NSString stringWithFormat:@"Node (Beacon) ID: %@ - ProxID: %@", self.ID, self.proximityUUID];
    }
    return [NSString stringWithFormat:@"Node (Beacon) ID: %@", self.ID];
}

- (NSString *)typeName {
    return @"BeaconNode";
}

@end
