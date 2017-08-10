//
//  NITTriggerRequestQueue.h
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITRecipeRepository;
@class NITTriggerRequest;
@class NITTriggerRequestQueue;

@protocol NITTriggerRequestQueueDelegate <NSObject>

- (void)triggerRequestQueue:(NITTriggerRequestQueue* _Nonnull)queue didFinishWithRequest:(NITTriggerRequest* _Nonnull)request;

@end

@interface NITTriggerRequestQueue : NSObject

@property (nonatomic, weak) id<NITTriggerRequestQueueDelegate> _Nullable delegate;

- (instancetype _Nonnull)initWithRepository:(NITRecipeRepository* _Nonnull)repository;

- (void)addRequest:(NITTriggerRequest* _Nonnull)request;

@end
