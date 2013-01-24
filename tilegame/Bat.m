//
//  Bat.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import "Bat.h"
#import "GameConstants.h"
#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "HelloWorldLayer.h"

@implementation Bat

@synthesize myLayer, sprite, hitPoints, speedInPixelsPerSec, behavior;

// required METHODS
// init
-(id)initWithLayer:(HelloWorldLayer*) layer andSpawnAt:(CGPoint) spawnPoint withBehavior:(int) initBehavior
{
    self = [super init];
    if(self)
    {
        
        // store the layer we belong to - not sure if this is needed or not
        myLayer = layer;
        behavior = initBehavior;

        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];  // preload creature sounds
        // set bat's stats
        self.hitPoints = 1;
        self.speedInPixelsPerSec = 33;
    
        sprite = [CCSprite spriteWithFile:@"bat2.png"];
        sprite.position = spawnPoint;
        
        [self addChild:sprite];
        // is this enough to display it?
        
        [self takeActions];
    }
    return self;
}

// for sampling during real actions
-(void)sampleCurrentPosition:(CGPoint) currentPoint  // this should be called (callbacked) once every kTimeStepSeconds for later animation on player2's side
{
    
}
// state changes like decreasing HP or killing a creature
-(void)wound:(int) hpLost
{
    hitPoints -= hpLost;

//  There's concurrency problems here so we have to wait for kill to be called from HelloWorldLayer first FIX
//    if(hitPoints < 1)
//        [self kill];
}
-(void)kill // possibly animate a death then remove this minion
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
    myLayer.numKills += 1;
    [myLayer.hud numKillsChanged:myLayer.numKills];

    // remove the sprite as a CCNode and cleanup
    [self removeChild:sprite cleanup:YES];

    // remove this bat from the layer's list
    // THIS MIGHT BE FUCKED FIX // not sure if it's OK to remove ourselves from the layer's array
    // this won't work because an element of the array will be deleted while the array is being run through
//    [myLayer.bats removeObject:self];
//    [myLayer removeChild:self cleanup:YES];
}

-(void)realSetBehaviour:(int) newBeahavior
{
    
}

-(void)realMove:(CGPoint) targetPoint
{
    
}

-(void)realExplode:(CGPoint) targetPoint
{
    
}



// for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)animateMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    
}
-(void)animateExplode:(CGPoint) targetPoint  // animate it exploding
{
    
}

-(void) takeActions
{
    // Actions depend on behavior setting
    // behavior must = kBehavior_idle in the case of re-playing opponent's last actions
    // begin doing shit with this entity (moving, attacking, etc)
    switch (behavior) {
        case kBehavior_idle:
            // do nothing but idle at sprite's location
            break;
        case kBehavior_default:
        {
            //rotate to face the player
            
            CGPoint diff = ccpSub(myLayer.player.position, sprite.position);
            float angleRadians = atanf((float)diff.y / (float)diff.x);
            float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
            float cocosAngle = -1 * angleDegrees;
            if(diff.x < 0)
                cocosAngle += 180;
            sprite.rotation = cocosAngle;
            
            // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
            int distancePixels = 10;
            ccTime actualDuration = distancePixels / speedInPixelsPerSec; //  0.3; //  v = d / t; t = d / v
            
            // create the actions
            // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
            // ccpNormalize calculates a unit vector given 2 point coordinates,...
            // and gives a hypotenous of length 1 with appropriate x,y
            id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(myLayer.player.position,sprite.position)), distancePixels)];
            // callback to this method again! If the entity has changed it's behavior, then a different case will be implemented
            id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(takeActions:)];
            [sprite runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
        }

            break;
        default:
            break;
    }
    
}


@end

