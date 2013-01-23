//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVGameStatus.h"

#define kDVAPIGameKey @"game" // name of the JSON key to get the gameStatus object out server's JSON response
#define kDVAPIErrorKey @"error" // name of the JSON key to get the error object out server's JSON response
#define kDVAPIErrorMsgKey @"message" // name of the JSON key to get the error message out JSON responses' error object

#define kDVAPIWrapperErrorDomain @"DVAPIWrapperErrorDomain" // used for creating new NSError obj from this class

@interface DVAPIWrapper : NSObject

- (id) init;

// creates a new game object on the server and returns the inital game status
- (void) postCreateNewGameThenCallBlock:(void (^)(NSError *, DVGameStatus *))block;

// gets the current game status from the server
- (void) getGameStatusThenCallBlock:(void (^)(NSError *, DVGameStatus *))block;

// post a dict of updates ex. {"melonsEaten":5} that needs to be sent to the opponent
// include {"isGameOver":"true"} in the dict when you have an update that ends the game
- (void) postUpdateGameWithUpdates:(NSDictionary *)updates ThenCallBlock:(void (^)(NSError *))block;

@end