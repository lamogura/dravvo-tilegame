//
//  Bat.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//
//@protocol Entity;

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Entity.h"
#import "CCSequence+Helper.h"
#import "ChangeableObject.h"
//#import "HelloWorldLayer.h"

@interface Bat : ChangeableObject <Entity>

//@property (nonatomic, unsafe_unretained) HelloWorldLayer* myLayer;
@property (nonatomic, strong) HelloWorldLayer* myLayer;
@property (nonatomic, strong) CCSprite* sprite;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, assign) int behavior;
@property (nonatomic, assign) CGPoint previousPosition;
@property (nonatomic, strong) NSMutableString* ownershipPlayerID;
@property (nonatomic, strong) NSMutableString* ownerAndEntityID;
@property (nonatomic, assign) int uniqueIntID;


// required METHODS
+(int)uniqueIntIDCounter;  // static function for providing unique integer IDs to each new instance of each particular entity kind

-(id)initWithLayer:(HelloWorldLayer*) layer andSpawnAt:(CGPoint) spawnPoint withBehavior:(int) initBehavior withPlayerOwner:(NSMutableString*) ownerPlayerID;
//-(id)initWithSpawnPoint:(CGPoint) spawnPoint withBehavior:(int) initBehavior;
//-(void)spwan:(CGPoint) spawnPoint;
// for sampling during real actions
// for later animation on player2's side

// sampleCurrentPosition will also push a string entry into historicalEventsList reporting its movement since its previous position
-(void)sampleCurrentPosition; //:(int) minionListIndex;
// state changes like decreasing HP or killing a creature
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
