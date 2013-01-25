//
//  ChangeableObject.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//  A ChangeableObject is an object which can do stuff, whether animate or change its state
//  All ChangeableObjects need to be able to record a historicalEventsList which will
//  later be pushed into one big list in HelloWorldLayer and pushed to the server

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface ChangeableObject : CCNode

@property (nonatomic, strong) NSMutableArray* historicalEventsList_local;

@end
