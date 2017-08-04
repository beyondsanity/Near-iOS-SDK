//
//  NITNetworkProvider.m
//  NearITSDK
//
//  Created by Francesco Leoni on 15/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITNetworkProvider.h"
#import "NITConfiguration.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"

#define NITApiVersion @"2"
#define NITNearVersion @"1"

static NITNetworkProvider *sharedProvider;

@interface NITNetworkProvider()

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NSString *baseUrl;

@end

@implementation NITNetworkProvider

- (instancetype)initWithConfiguration:(NITConfiguration *)configuration {
    self = [self init];
    if (self) {
        self.configuration = configuration;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.baseUrl = @"https://api.nearit.com";
    }
    return self;
}

+ (NITNetworkProvider*)sharedInstance {
    if (sharedProvider == nil) {
        sharedProvider = [[NITNetworkProvider alloc] init];
    }
    return sharedProvider;
}

- (NSURLRequest*)recipesProcessListWithJsonApi:(NITJSONAPI*)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:@"/recipes/process"];
    [request setHTTPMethod:@"POST"];
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonData];
    return request;
}

- (NSURLRequest *)processRecipeWithId:(NSString *)recipeId {
    return [self requestWithPath:[NSString stringWithFormat:@"/recipes/%@?filter[core][profile_id]=%@&include=reaction_bundle", recipeId, self.configuration.profileId]];
}

- (NSURLRequest *)evaluateRecipeWithId:(NSString*)recipeId jsonApi:(NITJSONAPI*)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:[NSString stringWithFormat:@"/recipes/%@/evaluate", recipeId]];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonData];
    
    return request;
}

- (NSURLRequest *)onlinePulseEvaluationWithJsonApi:(NITJSONAPI*)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:@"/recipes/evaluate"];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonData];
    
    return request;
}

- (NSURLRequest *)newProfileWithAppId:(NSString*)appId {
    NSMutableURLRequest *request = [self requestWithPath:@"/plugins/congrego/profiles"];
    [request setHTTPMethod:@"POST"];
    
    NITJSONAPI *jsonApi = [[NITJSONAPI alloc] init];
    NITJSONAPIResource *resource = [[NITJSONAPIResource alloc] init];
    resource.type = @"profiles";
    [resource addAttributeObject:appId forKey:@"app_id"];
    [jsonApi setDataWithResourceObject:resource];
    
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    
    return request;
}

- (NSURLRequest *)newInstallationWithJsonApi:(NITJSONAPI *)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:@"/installations"];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    
    return request;
}

- (NSURLRequest *)updateInstallationWithJsonApi:(NITJSONAPI *)jsonApi installationId:(NSString *)installationId {
    NSMutableURLRequest *request = [self requestWithPath:[NSString stringWithFormat:@"/installations/%@", installationId]];
    [request setHTTPMethod:@"PUT"];
    
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    return request;
}

- (NSURLRequest *)contentWithBundleId:(NSString *)bundleId {
    NSMutableURLRequest *request = [self requestWithPath:[NSString stringWithFormat:@"/plugins/content-notification/contents/%@?include=images,audio,upload", bundleId]];
    return request;
}

- (NSURLRequest*)contents {
    NSMutableURLRequest *request = [self requestWithPath:@"/plugins/content-notification/contents?include=images,audio,upload"];
    return request;
}

- (NSURLRequest*)feedbacks {
    return [self requestWithPath:@"/plugins/feedbacks/feedbacks"];
}

- (NSURLRequest *)sendFeedbackEventWithJsonApi:(NITJSONAPI *)jsonApi feedbackId:(NSString*)feedbackId {
    NSMutableURLRequest *request = [self requestWithPath:[NSString stringWithFormat:@"/plugins/feedbacks/feedbacks/%@/answers", feedbackId]];
    [request setHTTPMethod:@"POST"];
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    return request;
}

- (NSURLRequest *)geopolisNodes {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/geopolis/nodes?filter[app_id]=%@&include=**.children", [self.configuration appId]]];
}

- (NSURLRequest *)sendTrackingsWithJsonApi:(NITJSONAPI *)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:@"/trackings"];
    [request setHTTPMethod:@"POST"];
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    return request;
}

- (NSURLRequest *)sendGeopolisTrackingsWithJsonApi:(NITJSONAPI *)jsonApi {
    NSMutableURLRequest *request = [self requestWithPath:@"/plugins/geopolis/trackings"];
    [request setHTTPMethod:@"POST"];
    NSDictionary *json = [jsonApi toDictionary];
    NSData *jsonDataBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:jsonDataBody];
    return request;
}

- (NSURLRequest *)couponsWithProfileId:(NSString *)profileId {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/coupon-blaster/coupons?filter[claims.profile_id]=%@&include=claims,icon", profileId]];
}

- (NSURLRequest *)couponWithProfileId:(NSString *)profileId bundleId:(NSString *)bundleId {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/coupon-blaster/coupons/%@?filter[claims.profile_id]=%@&include=claims,icon", bundleId, profileId]];
}

- (NSURLRequest *)feedbackWithBundleId:(NSString *)bundleId {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/feedbacks/feedbacks/%@", bundleId]];
}

- (NSURLRequest *)customJSONWithBundleId:(NSString *)bundleId {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/json-sender/json_contents/%@", bundleId]];
}

- (NSURLRequest *)customJSONs {
    return [self requestWithPath:[NSString stringWithFormat:@"/plugins/json-sender/json_contents?filter[app_id]=%@", self.configuration.appId]];
}

- (NSURLRequest *)setUserDataWithJsonApi:(NITJSONAPI *)jsonApi profileId:(NSString*)profileId {
    NSMutableURLRequest *request = [self requestWithPath:[NSString stringWithFormat:@"/plugins/congrego/profiles/%@/data_points", profileId]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[jsonApi dataValue]];
    
    return request;
}

- (NSURLRequest *)timestamps {
    return [self requestWithPath:[NSString stringWithFormat:@"/timestamps/%@", self.configuration.appId]];
}

// MARK: - Private functions

- (NSDictionary*)buildCoreObject {
    NITConfiguration *config = self.configuration;
    NSMutableDictionary<NSString*, NSString*> *core = [[NSMutableDictionary alloc] init];
    if (config.appId && config.profileId && config.installationId) {
        [core setObject:config.profileId forKey:@"profile_id"];
        [core setObject:config.installationId forKey:@"installation_id"];
        [core setObject:config.appId forKey:@"app_id"];
    }
    return [NSDictionary dictionaryWithDictionary:core];
}

- (NSMutableURLRequest*)requestWithPath:(NSString*)path {
    NSURL *url = [NSURL URLWithString:[self.baseUrl stringByAppendingString:path]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [self setNearITHeaders:request];
    return request;
}

- (void)setNearITHeaders:(NSMutableURLRequest*)request {
    
    [request setValue:[NSString stringWithFormat:@"bearer %@", [self.configuration apiKey]] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Accept"];
    [request setValue:NITApiVersion forHTTPHeaderField:@"X-API-Version"];
    [request setValue:NITNearVersion forHTTPHeaderField:@"X-Near-Version"];
}

@end
