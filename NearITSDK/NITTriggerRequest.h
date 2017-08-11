//
//  NITTriggerRequest.h
//  NearITSDK
//
//  Created by francesco.leoni on 09/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITTrackingInfo;

@interface NITTriggerRequest : NSObject

@property (nonatomic, strong) NSString * _Nonnull pulsePlugin;
@property (nonatomic, strong) NSString * _Nonnull pulseAction;
@property (nonatomic, strong) NSString * _Nonnull pulseBundle;
@property (nonatomic, strong) NSString * _Nullable tagAction;
@property (nonatomic, strong) NSArray<NSString*>* _Nullable tags;
@property (nonatomic, strong) NITTrackingInfo * _Nonnull trackingInfo;

@end
