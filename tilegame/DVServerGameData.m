//
//  DVTextMessage.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVServerGameData.h"
#import "SBJson.h"

@implementation DVServerGameData

@synthesize gameID = _gameID;
@synthesize createdAt = _createdAt;

@synthesize nextTurn = _nextTurn;
@synthesize updates = _updates;
@synthesize gameOverStatus = _gameOverStatus;

- (id)initWithGameID:(NSString *)gameID updates:(NSArray *)gameUpdates gameOverStatus:(GameOverStatus)gameOverStatus
{
    if (self=[super init])
    {
        self.gameID = gameID;
        self.updates = gameUpdates;
        self.gameOverStatus = gameOverStatus;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *) dict
{
    if (self=[super init])
    {
        self.gameID = [dict objectForKey:@"_id"];
        self.nextTurn = [dict objectForKey:@"nextTurn"];
        
        if ([dict objectForKey:@"lastUpdate"] != [NSNull null])
        {
            NSString* updatesAsJSON = [dict objectForKey:@"lastUpdate"];
            self.updates = [updatesAsJSON JSONValue];
        }
        
        self.gameOverStatus = [[dict objectForKey:@"isGameOver"] intValue];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        NSDate *date;
        [formatter getObjectValue:&date forString:[dict objectForKey:@"createdAt"] range:nil error:nil];
        self.createdAt = date;
    }
    return self;
}

- (id)initWithJSONString:(NSString *)jsonString
{
    return [[DVServerGameData alloc] initWithDictionary:[jsonString JSONValue]];
}

@end