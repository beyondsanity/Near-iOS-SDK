//
//  NITRecipesApi.m
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITRecipesApi.h"
#import "NITConfiguration.h"
#import "NITEvaluationBodyBuilder.h"
#import "NITJSONAPI.h"
#import "NITRecipe.h"
#import "NITCoupon.h"
#import "NITClaim.h"
#import "NITImage.h"
#import "NITNetworkProvider.h"

@interface NITRecipesApi()

@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;

@end

@implementation NITRecipesApi

- (instancetype)initWithNetworkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration *)configuration evaluationBodyBuilder:(NITEvaluationBodyBuilder *)evaluationBodyBuilder {
    self = [super init];
    if (self) {
        self.networkManager = networkManager;
        self.configuration = configuration;
        self.evaluationBodyBuilder = evaluationBodyBuilder;
    }
    return self;
}

- (void)processRecipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, BOOL, NSError * _Nullable))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] recipesProcessListWithJsonApi:[self.evaluationBodyBuilder buildEvaluationBody]] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, NO, error);
        } else {
            [self registerClassesWithJsonApi:json];
            BOOL onlineEvaluation = YES;
            id metaOnline = [json metaForKey:@"online_evaluation"];
            if (metaOnline && [metaOnline isKindOfClass:[NSNumber class]]) {
                onlineEvaluation = [metaOnline boolValue];
            }
            NSArray<NITRecipe*>* recipes = [json parseToArrayOfObjects];
            completionHandler(recipes, onlineEvaluation, nil);
        }
    }];
}

// MARK - Utils

- (void)registerClassesWithJsonApi:(NITJSONAPI*)jsonApi {
    [jsonApi registerClass:[NITRecipe class] forType:@"recipes"];
    [jsonApi registerClass:[NITCoupon class] forType:@"coupons"];
    [jsonApi registerClass:[NITClaim class] forType:@"claims"];
    [jsonApi registerClass:[NITImage class] forType:@"images"];
}

@end
