//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVServerGameData.h"

#define kDVAPIGameKey @"game" // name of the JSON key to get the gameStatus object out server's JSON response
#define kDVAPIErrorKey @"error" // name of the JSON key to get the error object out server's JSON response
#define kDVAPIErrorMsgKey @"message" // name of the JSON key to get the error message out JSON responses' error object

#define kDVAPIWrapperErrorDomain @"DVAPIWrapperErrorDomain" // used for creating new NSError obj from this class

@interface DVAPIWrapper : NSObject

+ (DVAPIWrapper *) wrapper; // convenience method

- (id) init;

// creates a new game object on the server and returns the inital game status
- (void) postCreateNewGameThenCallBlock:(void (^)(NSError* error, DVServerGameData* status))block;

// gets the current game status from the server
- (void) getGameStatusForID:(NSString *)gameID ThenCallBlock:(void (^)(NSError* error, DVServerGameData* status))block;

- (void) postUpdateEvents:(NSArray *)events WithGameOverStatus:(GameOverStatus)status ThenCallBlock:(void (^)(NSError* error))block;

// use this to debug different things
- (void) postToURL:(NSString *)urlString UpdateEvents:(NSArray *)events WithGameOverStatus:(GameOverStatus)status ThenCallBlock:(void (^)(NSError* error))block;
@end