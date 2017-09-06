//
//  NITTreeLevel.h
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITNode;

typedef NS_ENUM(NSInteger, NITTreeLevelEvent) {
    NITTreeLevelEventEnter = 1,
    NITTreeLevelEventExit
};

@interface NITTreeLevel : NSObject

- (instancetype _Nonnull)initWithParent:(NITNode* _Nullable)parent children:(NSArray<NITNode*>* _Nullable)children;

- (BOOL)containsWithId:(NSString* _Nullable)ID;
- (BOOL)shouldConsiderEventWithId:(NSString* _Nullable)ID event:(NITTreeLevelEvent)event;

@end
