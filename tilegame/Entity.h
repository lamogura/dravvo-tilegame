//
//  Entity.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//
#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSequence+Helper.h"
#import <GameKit/GameKit.h>
//#import "HelloWorldLayer.h"

@class HelloWorldLayer;  // gotta do forward declaration

// Entity's include Bat, Missile, Shuriken, Player?
// IN the very least, make sure that all previous time step actions and animations are finished before performing the next time step's actions from main
@protocol Entity // <CCNode> // <NSObject>
@required

@property (nonatomic, strong) HelloWorldLayer* myLayer;
@property (nonatomic, strong) CCSprite* sprite;  // most things with pointers, nonatomic, strong ?
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, assign) int behavior;
@property (nonatomic, assign) CGPoint previousPosition;
@property (nonatomic, strong) NSMutableString* ownershipPlayerID;
@property (nonatomic, strong) NSMutableString* ownerAndEntityID;
@property (nonatomic, assign) int uniqueIntID;


+(int)uniqueIntIDCounter;  // static function for providing unique integer IDs to each new instance of each particular entity kind
-(id)initWithLayer:(HelloWorldLayer*) layer andSpawnAt:(CGPoint) spawnPoint withBehavior:(int) initBehavior withPlayerOwner:(NSMutableString*) ownerPlayerID;
//-(id)initWithSpawnPoint:(CGPoint) spawnPoint withBehavior:(int) initBehavior;
//-(void)spwan:(CGPoint) spawnPoint;
// for sampling during real actions for later animation on player2's side

// sampleCurrentPosition will also push a string entry into historicalEventsList reporting its movement since its previous position
// this string will be inserted SECOND in the local historicalEventsList just after the spawn
-(void)sampleCurrentPosition; //:(int) minionListIndex;

// State changes like decreasing HP or killing a creature
-(void)wound:(int) hpLost;
-(void)kill; // possibly animate a death then remove this minion


// List of real actions the entity can do to interact with the environment state changes
-(void)realUpdate;
-(void)realSetBehaviour:(int) newBeahavior;
-(void)realMove:(CGPoint) targetPoint;
-(void)realExplode:(CGPoint) targetPoint;

// List of historical animations that simluate past actions without any environment state changes, for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)aniMove:(CGPoint) targetPoint;  // will animate a historical move over time interval kTimeStepSeconds
-(void)aniExplode:(CGPoint) targetPoint;  // animate it exploding

-(void) takeActions;

@end