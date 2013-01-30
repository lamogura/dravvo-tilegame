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

@synthesize gameID;
@synthesize createdAt;

@synthesize nextTurn;
@synthesize lastUpdates;
@synthesize isGameOver;

- (id)initWithDictionary:(NSDictionary *) dict {
    self = [super init];
    if (self) {
        self.gameID = [dict objectForKey:@"_id"];
        self.nextTurn = [dict objectForKey:@"nextTurn"];
        
        if ([dict objectForKey:@"lastUpdate"] != [NSNull null]) {
            NSString* updatesAsJSON = [dict objectForKey:@"lastUpdate"];
            self.lastUpdates = [updatesAsJSON JSONValue];
        }
        
        self.isGameOver  = [@"true" isEqualToString:[dict objectForKey:@"isGameOver"]] ? YES : NO;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        NSDate *date;
        [formatter getObjectValue:&date forString:[dict objectForKey:@"createdAt"] range:nil error:nil];
        self.createdAt = date;
    }
    return self;
}

- (id)initWithJSONString:(NSString *)jsonString {
    return [[DVServerGameData alloc] initWithDictionary:[jsonString JSONValue]];
}

@end