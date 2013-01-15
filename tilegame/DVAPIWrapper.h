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

- (void) getGameStatusAndCallBlock:(void (^)(NSError *, DVGameStatus *))block;
//- (void) putUpdateGameWithStatus:(DVGameStatus *)status AndCallBlock:(void (^)(NSError *))block;
//- (void) postCreateNewGameAndCallBlock:(void (^)(NSError *, DVGameStatus *))block;

@end
