//
//  NITContentReaction.m
//  NearITSDK
//
//  Created by Francesco Leoni on 24/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITContentReaction.h"
#import "NITNetworkManager.h"
#import "NITNetworkProvider.h"
#import "NITContent.h"
#import "NITJSONAPI.h"
#import "NITConstants.h"
#import "NITRecipe.h"
#import "NITImage.h"
#import "NITAudio.h"
#import "NITUpload.h"
#import "NITLog.h"

#define CACHE_KEY @"ContentReaction"
#define LOGTAG @"ContentReaction"

NSString* const NITContentPluginName = @"content-notification";

@interface NITContentReaction()

@property (nonatomic, strong) NSArray<NITContent*> *contents;

@end

@implementation NITContentReaction

- (void)contentWithRecipe:(NITRecipe *)recipe completionHandler:(void (^)(id _Nullable content, NSError * _Nullable error))handler {
    if (self.contents == nil) {
        self.contents = [self.cacheManager loadArrayForKey:CACHE_KEY];
    }
    for(NITContent *content in self.contents) {
        if([content.ID isEqualToString:recipe.reactionBundleId]) {
            NITLogD(LOGTAG, @"Content found in cache");
            handler(content, nil);
            return;
        }
    }
    [self requestSingleReactionWithBundleId:recipe.reactionBundleId completionHandler:^(id content, NSError *requestError) {
        if(handler) {
            handler(content, requestError);
        }
    }];
}

- (void)contentWithReactionBundleId:(NSString *)reactionBundleId recipeId:(NSString* _Nonnull)recipeId completionHandler:(void (^)(id _Nullable, NSError * _Nullable))handler {
    if (handler) {
        [self requestSingleReactionWithBundleId:reactionBundleId completionHandler:^(id content, NSError *error) {
            handler(content, error);
        }];
    }
}

- (id)contentWithJsonReactionBundle:(NSDictionary<NSString *,id> *)jsonReactionBundle recipeId:(NSString * _Nonnull)recipeId{
    NITJSONAPI *json = [[NITJSONAPI alloc] initWithDictionary:jsonReactionBundle];
    [self registerJsonApiClasses:json];
    NSArray<NITContent*> *contents = [json parseToArrayOfObjects];
    if([contents count] > 0) {
        NITContent *content = [contents objectAtIndex:0];
        return content;
    }
    return nil;
}

- (void)requestSingleReactionWithBundleId:(NSString*)bundleId completionHandler:(void (^)(id content, NSError *error))handler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] contentWithBundleId:bundleId] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        
        if (error) {
            NITLogE(LOGTAG, @"Invalid content data from network error");
            NSError *anError = [NSError errorWithDomain:NITReactionErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey:@"Invalid content data", NSUnderlyingErrorKey: error}];
            handler(nil, anError);
        } else {
            [self registerJsonApiClasses:json];
            
            NSArray<NITContent*> *contents = [json parseToArrayOfObjects];
            if([contents count] > 0) {
                NITLogD(LOGTAG, @"Content found");
                NITContent *content = [contents objectAtIndex:0];
                handler(content, nil);
            } else {
                NITLogE(LOGTAG, @"Invalid content data from empty or invalid type of json");
                NSError *anError = [NSError errorWithDomain:NITReactionErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey:@"Invalid content data"}];
                handler(nil, anError);
            }
        }
    }];
}

- (void)refreshConfigWithCompletionHandler:(void(^)(NSError * _Nullable error))handler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] contents] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            self.contents = [self.cacheManager loadArrayForKey:CACHE_KEY];
            NSError *anError = [NSError errorWithDomain:NITReactionErrorDomain code:102 userInfo:@{NSLocalizedDescriptionKey:@"Invalid contents data", NSUnderlyingErrorKey: error}];
            if(handler) {
                handler(anError);
            }
        } else {
            [self registerJsonApiClasses:json];
            
            self.contents = [json parseToArrayOfObjects];
            [self.cacheManager saveWithArray:self.contents forKey:CACHE_KEY];
            if (handler) {
                handler(nil);
            }
        }
    }];
}

- (void)registerJsonApiClasses:(NITJSONAPI*)json {
    [json registerClass:[NITContent class] forType:@"contents"];
    [json registerClass:[NITImage class] forType:@"images"];
    [json registerClass:[NITAudio class] forType:@"audios"];
    [json registerClass:[NITUpload class] forType:@"uploads"];
}

@end
