//
//  NITTriggerRequestQueue.m
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTriggerRequestQueue.h"
#import "NITRecipeRepository.h"
#import "NITTriggerRequest.h"

static NSString *const processQueueLock = @"processQueue.lock";

@interface NITTriggerRequestQueue()

@property (nonatomic, strong) NITRecipeRepository *repository;
@property (atomic, strong) NSMutableArray<NITTriggerRequest*>* requests;
@property (atomic) BOOL isBusy;

@end

@implementation NITTriggerRequestQueue

- (instancetype)initWithRepository:(NITRecipeRepository *)repository {
    self = [super init];
    if (self) {
        self.repository = repository;
        self.requests = [[NSMutableArray alloc] init];
        self.isBusy = NO;
    }
    return self;
}


- (void)addRequest:(NITTriggerRequest *)request {
    [self.requests addObject:request];
    [self processQueue];
}

- (void)processQueue {
    @synchronized (processQueueLock) {
        if (self.isBusy) {
            return;
        }
        
        if ([self.requests count] == 0) {
            return;
        }
        
        self.isBusy = YES;
    }
    
    [self.repository syncWithCompletionHandler:^(NSError * _Nullable error, BOOL isUpdated) {
        NSArray<NITTriggerRequest*>* queuedRequests = [self.requests copy];
        if (isUpdated) {
            [self finishQueueWithRequests: queuedRequests];
        } else {
            for(NITTriggerRequest *request in queuedRequests) {
                [self.requests removeObject:request];
            }
        }
        self.isBusy = NO;
        [self processQueue];
    }];
}

- (void)finishQueueWithRequests:(NSArray<NITTriggerRequest*>*)requests {
    for(NITTriggerRequest *request in requests) {
        if ([self.delegate respondsToSelector:@selector(triggerRequestQueue:didFinishWithRequest:)]) {
            [self.delegate triggerRequestQueue:self didFinishWithRequest:request];
        }
        [self.requests removeObject:request];
    }
}

@end
