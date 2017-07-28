//
//  NITInstallation.m
//  NearITSDK
//
//  Created by Francesco Leoni on 23/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITInstallation.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"
#import "NITNetworkManager.h"
#import "NITNetworkProvider.h"
#import "NITConfiguration.h"
#import "NITConstants.h"
#import "NITReachability.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "NITLog.h"

#define LOGTAG @"Installation"
#define SDK_VERSION @"1.0.5"

@interface NITInstallation()

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITReachability *reachability;
@property (nonatomic) BOOL isBusy;
@property (nonatomic) BOOL isQueued;

@end

@implementation NITInstallation

- (instancetype)initWithConfiguration:(NITConfiguration*)configuration networkManager:(id<NITNetworkManaging>)networkManager reachability:(NITReachability * _Nonnull)reachability {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.networkManager = networkManager;
        self.reachability = reachability;
        self.bluetoothState = CBManagerStateUnknown;
        self.isBusy = NO;
        self.isQueued = NO;
    }
    return self;
}

- (void)registerInstallation {
    if (self.reachability.currentReachabilityStatus != NotReachable && !self.isBusy) {
        [self makeInstallation];
    } else { // Set installation as queued
        self.isQueued = YES;
    }
}

- (void)shouldRegisterInstallation {
    if (self.reachability.currentReachabilityStatus != NotReachable && !self.isBusy && self.isQueued) {
        [self makeInstallation];
    }
}

- (void)makeInstallation {
    self.isBusy = YES;
    self.isQueued = NO;
    NSString *realInstallationId = [[self configuration] installationId];
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    
    NITJSONAPIResource *resource = [self installationResourceWithInstallationId:realInstallationId];
    if (resource) {
        [jsonApi setDataWithResourceObject:resource];
    } else {
        self.isBusy = NO;
        return;
    }
    
    if (realInstallationId) {
        [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] updateInstallationWithJsonApi:jsonApi installationId:realInstallationId] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
            [self handleResponseWithJsonApi:json error:error completionHandler:^(NSString * _Nullable installationId, NSError * _Nullable error) {
                self.isBusy = NO;
                if (error) {
                    self.isQueued = YES;
                    NSNumber *statusCode = [error.userInfo objectForKey:NITHttpStatusCode];
                    if (statusCode && [statusCode integerValue] == 404) {
                        self.configuration.installationId = nil;
                        [self makeInstallation];
                    }
                    NITLogW(LOGTAG, @"Update installation failure");
                } else {
                    NITLogI(LOGTAG, @"Update installation registered");
                    if (self.isQueued) {
                        [self makeInstallation];
                    }
                }
            }];
        }];
    } else {
        [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] newInstallationWithJsonApi:jsonApi] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
            [self handleResponseWithJsonApi:json error:error completionHandler:^(NSString * _Nullable installationId, NSError * _Nullable error) {
                self.isBusy = NO;
                if (error) {
                    NITLogW(LOGTAG, @"New installation failure");
                    self.isQueued = YES;
                } else {
                    if (self.isQueued) {
                        NITLogD(LOGTAG, @"New installation registered");
                        self.isQueued = NO;
                        [self makeInstallation];
                    }
                }
            }];
        }];
    }
}

- (NITJSONAPIResource*)installationResourceWithInstallationId:(NSString*)installationId {
    NITConfiguration *config = [self configuration];
    
    if(config.profileId == nil) {
        return nil;
    }
    
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    if(installationId) {
        resource.ID = installationId;
    } else {
        resource.ID = @"";
    }
    resource.type = @"installations";
    [resource addAttributeObject:@"ios" forKey:@"platform"];
    NSOperatingSystemVersion opVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    [resource addAttributeObject:[NSString stringWithFormat:@"%ld.%ld", (long)opVersion.majorVersion, (long)opVersion.minorVersion] forKey:@"platform_version"];
    [resource addAttributeObject:SDK_VERSION forKey:@"sdk_version"];
    [resource addAttributeObject:config.appId forKey:@"app_id"];
    if(config.profileId) {
        [resource addAttributeObject:config.profileId forKey:@"profile_id"];
    }
    if (config.deviceToken) {
        [resource addAttributeObject:config.deviceToken forKey:@"device_identifier"];
    }
    
    if (self.bluetoothState == CBManagerStatePoweredOn) {
        [resource addAttributeObject:[NSNumber numberWithBool:YES] forKey:@"bluetooth"];
    } else {
        [resource addAttributeObject:[NSNumber numberWithBool:NO] forKey:@"bluetooth"];
    }
    
    CLAuthorizationStatus locationStatus = [CLLocationManager authorizationStatus];
    if (locationStatus == kCLAuthorizationStatusAuthorizedAlways || locationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [resource addAttributeObject:[NSNumber numberWithBool:YES] forKey:@"location"];
    } else {
        [resource addAttributeObject:[NSNumber numberWithBool:NO] forKey:@"location"];
    }
    
    return resource;
}

- (void)handleResponseWithJsonApi:(NITJSONAPI*)json error:(NSError*)error completionHandler:(void (^)(NSString * _Nullable installationId, NSError * _Nullable error))handler {
    NITConfiguration *config = [self configuration];
    if(error) {
        if(handler) {
            handler(nil, error);
        }
    } else {
        NITJSONAPIResource *resource = [json firstResourceObject];
        if (resource.ID) {
            if (handler) {
                config.installationId = resource.ID;
                handler(resource.ID, nil);
            }
        } else {
            NSError *newError = [[NSError alloc] initWithDomain:NITInstallationErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:@"Invalid installation found"}];
            handler(nil, newError);
        }
    }
}

@end
