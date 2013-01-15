//
//  DVTextMessage.h
//  iostest
//
//  Created by mogura on 12/8/12.
//  Copyright (c) 2012 mogura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVGameStatus : NSObject

@property NSString *username;
@property NSString *messageText;
@property NSDate *receivedAt;
@property NSString *dbID;

- (id)initWithDictionary:(NSDictionary *) dict;
- (id)initWithJSONString:(NSString *)jsonString;

+ (NSArray *)textMessageArrayFromJSON: (NSString *)jsonString;
    
@end
