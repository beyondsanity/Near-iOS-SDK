//
//  NITNotificationProcessor.h
//  NearITSDK
//
//  Created by Francesco Leoni on 27/06/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NOTPROC_RECIPE_ID @"recipe_id"
#define NOTPROC_REACTION_PLUGIN_ID @"reaction_plugin_id"
#define NOTPROC_REACTION_BUNDLE_ID @"reaction_bundle_id"
#define NOTPROC_REACTION_BUNDLE @"reaction_bundle"

@class NITRecipesManager;
@class NITReaction;

@interface NITNotificationProcessor : NSObject

- (instancetype _Nonnull)initWithRecipesManager:(NITRecipesManager* _Nonnull)recipesManager reactions:(NSDictionary<NSString*, NITReaction*> * _Nonnull)reactions;
- (BOOL)processNotificationWithUserInfo:(NSDictionary<NSString *,id> * _Nonnull)userInfo completion:(void (^_Nullable)(id _Nullable object, NSString * _Nullable recipeId, NSError* _Nullable error))completionHandler;
- (BOOL)isRemoteNotificationWithUserInfo:(NSDictionary<NSString*, id>* _Nonnull)userInfo;

@end
