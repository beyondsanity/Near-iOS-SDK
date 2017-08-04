//
//  NITTimestamp.h
//  NearITSDK
//
//  Created by francesco.leoni on 04/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITResource.h"

@interface NITTimestamp : NITResource

@property (nonatomic, strong) NSString *what;
@property (nonatomic, strong) NSNumber *time;

@end
