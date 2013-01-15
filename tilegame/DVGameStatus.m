//
//  DVTextMessage.m
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import "DVGameStatus.h"
#import "SBJson.h"

@implementation DVGameStatus

@synthesize username;
@synthesize messageText;
@synthesize receivedAt;
@synthesize dbID;

- (id)initWithDictionary:(NSDictionary *) dict {
    self = [super init];
    if (self) {
        self.username    = [dict objectForKey:@"username"];
        self.messageText = [dict objectForKey:@"message_text"];
        self.dbID        = [dict objectForKey:@"_id"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        NSDate *date;
        [formatter getObjectValue:&date forString:[dict objectForKey:@"received_at"] range:nil error:nil];
        self.receivedAt = date;
    }
    return self;
}

- (id)initWithJSONString:(NSString *)jsonString {
    return [[DVGameStatus alloc] initWithDictionary:[jsonString JSONValue]];
}

+ (NSArray *)textMessageArrayFromJSON: (NSString *)jsonString {
    NSArray *jsonMessages = [jsonString JSONValue];
    NSMutableArray *messages = [[NSMutableArray alloc] initWithCapacity:[jsonMessages count]];
    
    for (NSDictionary *msg in jsonMessages) {
        [messages addObject:[[DVGameStatus alloc] initWithDictionary:msg]];
    }
    return (NSArray *)messages; //convert back to standard array
}
@end
