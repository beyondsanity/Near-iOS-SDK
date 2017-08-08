//
//  NITTestCase.h
//  NearITSDK
//
//  Created by Francesco Leoni on 28/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITRecipe.h"
#import "NITContent.h"
#import "NITImage.h"
#import "NITCoupon.h"
#import "NITJSONAPI.h"
#import "NITJSONAPIResource.h"
#import "NITFeedback.h"
#import "NITConfiguration.h"
#import "NITNetworkMockManger.h"

@interface NITTestCase : XCTestCase

- (NITRecipe*)recipeWithContentsOfFile:(NSString*)filename;
- (NITFeedback*)feedbackWithContentsOfFile:(NSString*)filename;
- (NSArray<NITContent*>*)contentsWithContentsOfFile:(NSString*)filename;
- (NITJSONAPI*)jsonApiWithContentsOfFile:(NSString*)filename;
- (NSDictionary*)jsonWithContentsOfFile:(NSString*)filename;
- (void)executeOnClientRunLoopAfterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)block;
- (NITJSONAPI*)makeTimestampsResponseWithTimeInterval:(NSTimeInterval)timeInterval;
- (NITJSONAPI*)simpleJsonApi;

@end
