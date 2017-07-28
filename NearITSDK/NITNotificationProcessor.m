//
//  NITNotificationProcessor.m
//  NearITSDK
//
//  Created by Francesco Leoni on 27/06/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITNotificationProcessor.h"
#import "NITRecipesManager.h"
#import "NITReaction.h"
#import "NITRecipe.h"
#import "NITJSONAPI.h"
#import "NSData+Zip.h"
#import "NITConstants.h"
#import "NITSimpleNotification.h"
#import "NITLog.h"
#import "NITSimpleNotificationReaction.h"

#define LOGTAG @"NotificationProcessor"

@interface NITNotificationProcessor()

@property (nonatomic, strong) NITRecipesManager *recipesManager;
@property (nonatomic, strong) NSDictionary<NSString*, NITReaction*> *reactions;

@end

@implementation NITNotificationProcessor

- (instancetype)initWithRecipesManager:(NITRecipesManager *)recipesManager reactions:(NSDictionary<NSString*, NITReaction*> *)reactions {
    self = [super init];
    if (self) {
        self.recipesManager = recipesManager;
        self.reactions = reactions;
    }
    return self;
}

- (BOOL)processNotificationWithUserInfo:(NSDictionary<NSString *,id> *)userInfo completion:(void (^)(id _Nullable, NSString * _Nullable, NSError * _Nullable))completionHandler {
    
    if(userInfo == nil) {
        if (completionHandler) {
            NSError *anError = [NSError errorWithDomain:NITNotificationProcessorDomain code:101 userInfo:@{NSLocalizedDescriptionKey:@"Invalid userInfo"}];
            completionHandler(nil, nil, anError);
        }
        return NO;
    }
    
    NSString *recipeId = [userInfo objectForKey:NOTPROC_RECIPE_ID];
    NSString *reactionPluginId = [userInfo objectForKey:NOTPROC_REACTION_PLUGIN_ID];
    NSString *reactionBundleId = [userInfo objectForKey:NOTPROC_REACTION_BUNDLE_ID];
    NSString *reactionBundle = [userInfo objectForKey:NOTPROC_REACTION_BUNDLE];
    NSDictionary<NSString*, id> *aps = [userInfo objectForKey:@"aps"];
    id alert = [aps objectForKey:@"alert"];
    BOOL isReactionBundleSuccess = NO;
    
    if ([reactionPluginId isEqualToString:NITSimpleNotificationPluginName] && alert && recipeId) {
        NITSimpleNotification *simple = [[NITSimpleNotification alloc] init];
        if ([alert isKindOfClass:[NSString class]]) {
            simple.message = (NSString*)alert;
        } else if([alert isKindOfClass:[NSDictionary class]]) {
            NSString *body = [alert objectForKey:@"body"];
            simple.message = body;
        }
        if (completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(simple, recipeId, nil);
            }];
        }
        return YES;
    } else if (reactionBundle && reactionPluginId && recipeId) {
        NSData *zipData = [NSData dataFromBase64String:reactionBundle];
        NSData *unzippedData = [zipData zlibInflate];
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:unzippedData options:NSJSONReadingMutableContainers error:&jsonError];
        if (json) {
            NITReaction *reaction = [self.reactions objectForKey:reactionPluginId];
            if (reaction) {
                id content = [reaction contentWithJsonReactionBundle:json recipeId:recipeId];
                if (content) {
                    isReactionBundleSuccess = YES;
                    if (completionHandler) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            completionHandler(content, recipeId, nil);
                        }];
                    }
                }
            }
        }
    }
    if(reactionPluginId && reactionBundleId && recipeId && !isReactionBundleSuccess) {
        NITReaction *reaction = [self.reactions objectForKey:reactionPluginId];
        if(reaction) {
            [self processWithReactionBundleId:reactionBundleId recipeId:recipeId reaction:reaction completionHandler:^(id _Nullable content, NSError * _Nullable error) {
                if (error) {
                    [self processWithRecipeId:recipeId completionHandler:^(id _Nullable content, NSError * _Nullable error) {
                        if (error) {
                            if (completionHandler) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    completionHandler(nil, recipeId, error);
                                }];
                            }
                        } else {
                            if (completionHandler) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    completionHandler(content, recipeId, nil);
                                }];
                            }
                        }
                    }];
                } else {
                    if (completionHandler) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            completionHandler(content, recipeId, nil);
                        }];
                    }
                }
            }];
        }
    } else if (recipeId && !isReactionBundleSuccess) {
        [self processWithRecipeId:recipeId completionHandler:^(id _Nullable content, NSError * _Nullable error) {
            if (error) {
                if (completionHandler) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completionHandler(nil, recipeId, error);
                    }];
                }
            } else {
                if (completionHandler) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completionHandler(content, recipeId, nil);
                    }];
                }
            }
        }];
    }
    
    BOOL isRemote = [self isRemoteNotificationWithUserInfo:userInfo];
    
    if (isRemote) {
        [self.recipesManager sendTrackingWithRecipeId:recipeId event:NITRecipeNotified];
        return YES;
    } else {
        NITLogE(LOGTAG, @"Invalid recipe");
        if (completionHandler) {
            NSError *anError = [NSError errorWithDomain:NITNotificationProcessorDomain code:102 userInfo:@{NSLocalizedDescriptionKey:@"Invalid recipe"}];
            completionHandler(nil, nil, anError);
        }
        return NO;
    }
}

- (BOOL)isRemoteNotificationWithUserInfo:(NSDictionary<NSString*, id>*)userInfo {
    NSString *recipeId = [userInfo objectForKey:NOTPROC_RECIPE_ID];
    NSString *reactionPluginId = [userInfo objectForKey:NOTPROC_REACTION_PLUGIN_ID];
    NSString *reactionBundleId = [userInfo objectForKey:NOTPROC_REACTION_BUNDLE_ID];
    NSString *reactionBundle = [userInfo objectForKey:NOTPROC_REACTION_BUNDLE];
    if(reactionPluginId && reactionBundleId && recipeId) {
        return YES;
    } else if(reactionBundle && reactionPluginId && recipeId) {
        return YES;
    } else if(recipeId) {
        return YES;
    }
    return NO;
}

- (void)processWithReactionBundleId:(NSString*)reactionBundleId recipeId:(NSString*)recipeId reaction:(NITReaction*)reaction completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    [reaction contentWithReactionBundleId:reactionBundleId recipeId:recipeId completionHandler:^(id  _Nullable content, NSError * _Nullable error) {
        if (error && completionHandler) {
            completionHandler(nil, error);
        } else if (content && completionHandler) {
            completionHandler(content, nil);
        }
    }];
}

- (void)processWithRecipeId:(NSString*)recipeId completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    [self.recipesManager processRecipe:recipeId completion:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        if (recipe) {
            NITReaction *reaction = [self.reactions objectForKey:recipe.reactionPluginId];
            if(reaction) {
                [reaction contentWithRecipe:recipe completionHandler:^(id _Nonnull content, NSError * _Nullable error) {
                    if(error) {
                        if (completionHandler) {
                            completionHandler(nil, error);
                        }
                    } else {
                        if (completionHandler) {
                            completionHandler(content, nil);
                        }
                    }
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }
    }];
}

@end
