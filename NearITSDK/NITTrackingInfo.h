//
//  NITTrackingInfo.h
//  NearITSDK
//
//  Created by francesco.leoni on 11/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NITTrackingInfo : NSObject

- (BOOL)addExtraWithObject:(NSString*)object key:(NSString*)key;
- (NSString *)recipeId;
- (void)setRecipeId:(NSString *)recipeId;

@end
