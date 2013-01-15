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

- (void) getAllMessagesAndCallBlock:(void (^)(NSError *, NSArray *))block;
- (void) sendMessage:(DVGameStatus *)msg AndCallBlock:(void (^)(NSError *, DVGameStatus *msg))block;
- (void) deleteMessage:(DVGameStatus *)msg AndCallBlock:(void (^)(NSError *))block;

@end
