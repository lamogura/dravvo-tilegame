//
//  DVAPIWrapper.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVServerGameData.h"

#define kDVAPIJSONResponseKey_Game @"game" // name of the JSON key to get the gameStatus object out server's JSON response
#define kDVAPIJSONResponseKey_ErrorDict @"error" // name of the JSON key to get the error object out server's JSON response
#define kDVAPIJSONResponseErrorKey_Message @"message" // name of the JSON key to get the error message out JSON responses' error object

#define kDVAPIWrapperErrorDomain @"DVAPIWrapperErrorDomain" // used for creating new NSError obj from this class

#define kDVAPIServerURL @"http://dravvo.ap01.aws.af.cm" // server
//#define kDVAPIServerURL @"http://192.168.20.2:3000" // laptop through iphone
//#define kDVAPIServerURL @"http://192.168.1.116:3000" // laptop through router

@interface DVAPIWrapper : NSObject

+ (DVAPIWrapper *) staticWrapper; // convenience method

- (id) init;

// creates a new game object on the server and returns the inital game status
- (void) createNewGameForDeviceToken:(NSString *)deviceToken callbackBlock:(void (^)(NSError* error, DVServerGameData* status))block;

// gets the current game status from the server
- (void) getGameStatusForID:(NSString *)gameID callbackBlock:(void (^)(NSError* error, DVServerGameData* status))block;

// post gaame updates to server
- (void) postGameUpdates:(NSArray *)updates gameOverStatus:(GameOverStatus)gameOverStatus forGameID:(NSString *)gameID deviceToken:(NSString *)deviceToken callbackBlock:(void (^)(NSError* error))block;

@end