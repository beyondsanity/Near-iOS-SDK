//
//  NITEvaluationBodyBuilder.h
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITConfiguration;
@class NITRecipeHistory;
@class NITDateManager;
@class NITJSONAPI;

@interface NITEvaluationBodyBuilder : NSObject

- (instancetype _Nonnull)initWithConfiguration:(NITConfiguration* _Nonnull)configuration recipeHistory:(NITRecipeHistory* _Nonnull)recipeHistory dateManager:(NITDateManager* _Nonnull)dateManager;

- (NITJSONAPI* _Nonnull)buildEvaluationBody;
- (NITJSONAPI* _Nonnull)buildEvaluationBodyWithPlugin:(NSString* _Nullable)plugin action:(NSString* _Nullable)action bundle:(NSString* _Nullable)bundle;

@end
