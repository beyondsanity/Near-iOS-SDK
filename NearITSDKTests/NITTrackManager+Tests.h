//
//  NITTrackManager+Tests.h
//  NearITSDK
//
//  Created by Francesco Leoni on 21/04/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTrackManager.h"

@class NITTrackRequest;

@interface NITTrackManager (Tests)

- (NSMutableArray *)requests;
- (NSDate*)currentDate;
- (void)sendTrackings;
- (NSArray<NITTrackRequest*>*)availableRequests;

@end
