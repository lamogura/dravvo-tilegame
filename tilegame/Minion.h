//
//  Minion.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//
#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"

// multiplayer other player object
// NOTE: might need to make a queue of actinos to perform
// IN the very least, make sure that all previous time step actions and animations are finished before performing the next time step's actions from main
@interface Minion : CCNode
{
    HelloWorldLayer* myLayer;
    
    // player should also posess an array of minion objects
    
    
}

@property (nonatomic, retain) HelloWorldLayer* myLayer;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) int speedInPixelsPerSec;

-(id)initWithLayer:(HelloWorldLayer*) layer;
// for sampling during real actions
-(void)sampleCurrentPosition:(CGPoint) currentPoint;  // this should be called (callbacked) once every kTimeStepSeconds for later animation on player2's side
// for later animation re-play on player2's side

// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)animateMove:(CGPoint) targetPoint;  // will animate a historical move over time interval kTimeStepSeconds
-(void)animateExplode:(CGPoint) targetPoint;  // animate it exploding

// state changes like decreasing HP or killing a creature
-(void)wound:(int) hpLost;
-(void)kill; // possibly animate a death then remove this minion


@end