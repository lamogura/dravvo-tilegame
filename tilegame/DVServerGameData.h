//
//  DVTextMessage.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GameOverStatus_Ongoing = 0,
    GameOverStatus_HostWin,
    GameOverStatus_GuestWin,
} GameOverStatus;

@interface DVServerGameData : NSObject

@property (nonatomic, copy) NSString *gameID;
@property (nonatomic, retain) NSDate *createdAt;

@property (nonatomic, copy) NSString *nextTurn;
@property (nonatomic, retain) NSArray *updates;
@property (nonatomic, assign) GameOverStatus gameOverStatus;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithJSONString:(NSString *)jsonString;

@end