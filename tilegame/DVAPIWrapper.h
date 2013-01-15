//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVGameStatus.h"

@interface DVAPIWrapper : NSObject

- (id) init;

- (void) getGameStatusThenCallBlock:(void (^)(NSError *, DVGameStatus *))block;
- (void) postCreateNewGameThenCallBlock:(void (^)(NSError *, DVGameStatus *))block;
// make a "isGameOver" key with value "true" or "false" to send to the server
- (void) putUpdateGameWithUpdates:(NSDictionary *)updates ThenCallBlock:(void (^)(NSError *))block;
@end
