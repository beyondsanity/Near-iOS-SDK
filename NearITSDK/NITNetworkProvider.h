//
//  NITNetworkProvider.h
//  NearITSDK
//
//  Created by Francesco Leoni on 15/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITJSONAPI;
@class NITConfiguration;

@interface NITNetworkProvider : NSObject

- (instancetype _Nonnull)initWithConfiguration:(NITConfiguration* _Nonnull)configuration;
- (void)setConfiguration:(NITConfiguration * _Nonnull)configuration;
+ (NITNetworkProvider* _Nonnull)sharedInstance;

- (NSURLRequest* _Nonnull)recipesProcessListWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)processRecipeWithId:(NSString* _Nonnull)recipeId;
- (NSURLRequest* _Nonnull)evaluateRecipeWithId:(NSString* _Nonnull)recipeId jsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)onlinePulseEvaluationWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)newProfileWithAppId:(NSString* _Nonnull)appId;
- (NSURLRequest* _Nonnull)geopolisNodes;
- (NSURLRequest* _Nonnull)newInstallationWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)updateInstallationWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi installationId:(NSString* _Nonnull)installationId;
- (NSURLRequest* _Nonnull)contentWithBundleId:(NSString* _Nonnull)bundleId;
- (NSURLRequest* _Nonnull)contents;
- (NSURLRequest* _Nonnull)sendTrackingsWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)sendGeopolisTrackingsWithJsonApi:(NITJSONAPI * _Nonnull)jsonApi;
- (NSURLRequest* _Nonnull)couponsWithProfileId:(NSString* _Nonnull)profileId;
- (NSURLRequest* _Nonnull)couponWithProfileId:(NSString* _Nonnull)profileId bundleId:(NSString* _Nonnull)bundleId;
- (NSURLRequest* _Nonnull)feedbackWithBundleId:(NSString* _Nonnull)bundleId;
- (NSURLRequest* _Nonnull)feedbacks;
- (NSURLRequest* _Nonnull)sendFeedbackEventWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi feedbackId:(NSString* _Nonnull)feedbackId;
- (NSURLRequest* _Nonnull)customJSONWithBundleId:(NSString* _Nonnull)bundleId;
- (NSURLRequest* _Nonnull)customJSONs;
- (NSURLRequest* _Nonnull)setUserDataWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi profileId:(NSString* _Nonnull)profileId;
- (NSURLRequest* _Nonnull)timestamps;

@end
