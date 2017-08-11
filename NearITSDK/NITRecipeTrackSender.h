//
//  NITRecipeTrackSender.h
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITConfiguration;
@class NITRecipeHistory;
@class NITTrackManager;
@class NITDateManager;
@class NITTrackingInfo;

@interface NITRecipeTrackSender : NSObject

- (instancetype _Nonnull)initWithConfiguration:(NITConfiguration* _Nonnull)configuration history:(NITRecipeHistory* _Nonnull)history trackManager:(NITTrackManager* _Nonnull)trackManager dateManager:(NITDateManager* _Nonnull)dateManager;
- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event;
- (void)sendTrackingWithTrackingInfo:(NITTrackingInfo * _Nullable)trackingInfo event:(NSString* _Nullable)event;

@end
