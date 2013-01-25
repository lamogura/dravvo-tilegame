//
//  Player.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//
@class HelloWorldLayer;
#import <Foundation/Foundation.h>
#import "cocos2d.h"
//#import "HelloWorldLayer.h"
#import "ChangeableObject.h"

@interface Player : ChangeableObject

@property (nonatomic, strong) HelloWorldLayer* myLayer;
@property (nonatomic, strong) CCSprite* sprite;
@property (nonatomic, assign) NSString* playerID;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) BOOL isAlive;
@property (nonatomic, assign) CGPoint initialSpawnPoint;
@property (nonatomic, strong) NSMutableArray* playerMinionList;

-(id)initWithLayer:(HelloWorldLayer*) layer andPlayerID:(NSString*)plyrID andSpawnAt:(CGPoint) spawnPoint;
-(void)sampleCurrentPosition;
-(void)wound:(int) hpLost;
-(void)kill; // possibly animate a death then remove this minion
-(void)regenerate;
-(void)initializeStats;


@end
