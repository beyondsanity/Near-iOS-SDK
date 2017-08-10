//
//  NITRecipesApiTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITRecipesApi.h"
#import "NITNetworkMockManger.h"
#import "NITConfiguration.h"
#import "NITEvaluationBodyBuilder.h"
#import "NITConstants.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface NITRecipesApiTest : NITTestCase

@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITEvaluationBodyBuilder *evaluationBodyBuilder;

@end

@implementation NITRecipesApiTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.configuration = mock([NITConfiguration class]);
    self.evaluationBodyBuilder = mock([NITEvaluationBodyBuilder class]);
    
    [given(self.configuration.profileId) willReturn:@"profile-id"];
    [given(self.configuration.installationId) willReturn:@"installation-id"];
    [given(self.configuration.appId) willReturn:@"app-id"];
    
    [given([self.evaluationBodyBuilder buildEvaluationBody]) willReturn:[self simpleJsonApi]];
    [given([self.evaluationBodyBuilder buildEvaluationBodyWithPlugin:anything() action:anything() bundle:anything()]) willReturn:[self simpleJsonApi]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testProcessRecipes {
    NITJSONAPI *json = [self jsonApiWithContentsOfFile:@"recipes"];
    NITNetworkMockManger *network = [[NITNetworkMockManger alloc] init];
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return json;
    };
    
    XCTestExpectation *exp = [self expectationWithDescription:@"api"];
    NITRecipesApi *api = [[NITRecipesApi alloc] initWithNetworkManager:network configuration:self.configuration evaluationBodyBuilder:self.evaluationBodyBuilder];
    // Test a valid json
    [api processRecipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, BOOL pulseOnline, NSError * _Nullable error) {
        XCTAssertFalse(pulseOnline);
        XCTAssertNil(error);
        XCTAssertTrue([recipes count] == 6);
        
        [exp fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    XCTestExpectation *expError = [self expectationWithDescription:@"api-error"];
    
    // Test an invalid server response
    [api processRecipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, BOOL pulseOnline, NSError * _Nullable error) {
        XCTAssertFalse(pulseOnline);
        XCTAssertNotNil(error);
        XCTAssertNil(recipes);
        
        [expError fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFetchRecipe {
    NITJSONAPI *json = [self jsonApiWithContentsOfFile:@"response_online_recipe"];
    NITNetworkMockManger *network = [[NITNetworkMockManger alloc] init];
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return json;
    };
    
    XCTestExpectation *exp = [self expectationWithDescription:@"api"];
    NITRecipesApi *api = [[NITRecipesApi alloc] initWithNetworkManager:network configuration:self.configuration evaluationBodyBuilder:self.evaluationBodyBuilder];
    
    // Test a valid recipe json
    [api fetchRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(recipe);
        [exp fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return [self simpleJsonApi];
    };
    XCTestExpectation *expInvalid = [self expectationWithDescription:@"api-invalid"];
    
    // Test an invalid json
    [api fetchRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:NITRecipeErrorDomain]);
        XCTAssertNil(recipe);
        [expInvalid fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    XCTestExpectation *expError = [self expectationWithDescription:@"api-error"];
    
    // Test an invalid server response
    [api fetchRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertNil(recipe);
        [expError fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testEvaluateRecipe {
    NITJSONAPI *json = [self jsonApiWithContentsOfFile:@"response_coupon_evaluated_recipe"];
    NITNetworkMockManger *network = [[NITNetworkMockManger alloc] init];
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return json;
    };
    
    XCTestExpectation *exp = [self expectationWithDescription:@"api"];
    NITRecipesApi *api = [[NITRecipesApi alloc] initWithNetworkManager:network configuration:self.configuration evaluationBodyBuilder:self.evaluationBodyBuilder];
    
    // Test a valid recipe json
    [api evaluateRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(recipe);
        [exp fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return [self simpleJsonApi];
    };
    XCTestExpectation *expInvalid = [self expectationWithDescription:@"api-invalid"];
    
    // Test an invalid json
    [api evaluateRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:NITRecipeErrorDomain]);
        XCTAssertNil(recipe);
        [expInvalid fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    XCTestExpectation *expError = [self expectationWithDescription:@"api-error"];
    
    // Test an invalid server response
    [api evaluateRecipeWithId:@"recipeId" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertNil(recipe);
        [expError fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testOnlinePulse {
    NITJSONAPI *json = [self jsonApiWithContentsOfFile:@"response_pulse_evaluation"];
    NITNetworkMockManger *network = [[NITNetworkMockManger alloc] init];
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return json;
    };
    
    XCTestExpectation *exp = [self expectationWithDescription:@"api"];
    NITRecipesApi *api = [[NITRecipesApi alloc] initWithNetworkManager:network configuration:self.configuration evaluationBodyBuilder:self.evaluationBodyBuilder];
    
    // Test a valid recipe json
    [api onlinePulseEvaluationWithPlugin:@"plugin" action:@"action" bundle:@"bundle" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(recipe);
        [exp fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return [self simpleJsonApi];
    };
    XCTestExpectation *expInvalid = [self expectationWithDescription:@"api-invalid"];
    
    // Test an invalid json
    [api onlinePulseEvaluationWithPlugin:@"plugin" action:@"action" bundle:@"bundle" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.domain isEqualToString:NITRecipeErrorDomain]);
        XCTAssertNil(recipe);
        [expInvalid fulfill];
    }];
    
    network.mock = ^NITJSONAPI *(NSURLRequest *request) {
        return nil;
    };
    XCTestExpectation *expError = [self expectationWithDescription:@"api-error"];
    
    // Test an invalid server response
    [api onlinePulseEvaluationWithPlugin:@"plugin" action:@"action" bundle:@"bundle" completionHandler:^(NITRecipe * _Nullable recipe, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertNil(recipe);
        [expError fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end
