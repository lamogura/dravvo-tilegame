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
#import "CoreGameLayer.h"
#import "DVMacros.h"

static int _uniqueIDCounter = 0;

@implementation Bat

#pragma mark - Entity overrides

+(int)nextUniqueID  // static function for providing unique integer IDs to each new instance of each particular entity kind
{
    return _uniqueIDCounter++;
}

-(id)initInLayerWithoutCache:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint withBehavior:behavior ownedBy:(EntityNode *)owner])
    {
        self.entityType = kEntityTypeBat;
        self.uniqueID = [Bat nextUniqueID];
        
        // set bat's stats
        self.hitPoints = kEntityBatHitPoints;
        self.speedInPixelsPerSec = kEntityBatSpeedPPS;
        
        if(self.owner.uniqueID == 2)
            self.sprite = [CCSprite spriteWithFile:@"batRed.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"batGreen.png"];

        self.sprite.position = self.lastPoint = spawnPoint;

        [self addChild:self.sprite];
        
        [self.gameLayer addChild:self];
    }
    return self;
   
}

-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint withBehavior:behavior ownedBy:(EntityNode *)owner])
    {
        self.entityType = kEntityTypeBat;
        self.uniqueID = uniqueID;
        
        // set bat's stats
        self.hitPoints = kEntityBatHitPoints;
        self.speedInPixelsPerSec = kEntityBatSpeedPPS;
        
        if(self.owner.uniqueID == 2)
            self.sprite = [CCSprite spriteWithFile:@"batRed.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"batGreen.png"];
        self.lastPoint = spawnPoint;
        self.sprite.position = self.lastPoint;
        
        // the action is to pause the sprite for kReplayTickLengthSeconds time
        id actionStall = [CCActionInterval actionWithDuration:delay];  // DEBUG does this work??
        
        self.sprite.visible = NO;
        
        id actionAppear = [CCCallBlock actionWithBlock:^(void){
            self.sprite.visible = YES;
        }];
        
        [self.actionsToBePlayed addObject:actionStall];  // change to this for multiplay
        [self.actionsToBePlayed addObject:actionAppear];
        
        [self addChild:self.sprite];
        
        [self.gameLayer addChild:self];
    }
    return self;
}


-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint withBehavior:behavior ownedBy:(EntityNode *)owner])
    {
        self.entityType = kEntityTypeBat;
        self.uniqueID = [Bat nextUniqueID];

        // set bat's stats
        self.hitPoints = kEntityBatHitPoints;
        self.speedInPixelsPerSec = kEntityBatSpeedPPS;
    
        if(self.owner.uniqueID == 2)
            self.sprite = [CCSprite spriteWithFile:@"batRed.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"batGreen.png"];

        self.sprite.position = self.lastPoint = spawnPoint;

        [self addChild:self.sprite];
        
        [self cacheStateForEvent:DVEvent_Spawn];
        
        [self.gameLayer addChild:self];
    }
    return self;
}

-(void)kill // possibly animate a death then remove this minion
{
    // since we instantly erase and remove this bat here, audio won't have a chance to play. we have to do it in HelloWorldLayer logic
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
//    [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombie.m4ra"];

    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];

    // remove the sprite as a CCNode and cleanup
  
    [self cacheStateForEvent:DVEvent_Kill];
    [self removeChild:self.sprite cleanup:YES];
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d kill %@ %d -1 -1",
                               myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"kill...%@",activityEntry);
*/

    // remove this bat from the layer's list
    // THIS MIGHT BE FUCKED FIX // not sure if it's OK to remove ourselves from the layer's array
    // this won't work because an element of the array will be deleted while the array is being run through
//    [myLayer.bats removeObject:self];
//    [myLayer removeChild:self cleanup:YES];
}

-(void)realUpdate
{
    // Bat moves toward the player, in the test case
    // calculate duration of how far bat can fly during kTickLengthSeconds time
    // travel there and then do nothing until the next update is called
    
    // Actions depend on behavior setting
    // behavior must = kBehavior_idle in the case of re-playing opponent's last actions
    // begin doing shit with this entity (moving, attacking, etc)
    switch (self.behavior) {
        case DVCreatureBehaviorIdle:
            // do nothing but idle at sprite's location
            break;
        case DVCreatureBehaviorDefault:
        {
            //rotate to face the opponent
            CoreGameLayer* layer = (CoreGameLayer *)self.gameLayer;

            CGPoint diff = ccpSub(layer.opponent.sprite.position, self.lastPoint);
            
            // Determine angle for the missile to face
            // basic trig stuff using touch info a character position calculations from above
            float angleRadians = atanf(diff.y / (float)diff.x);
            float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
            float cocosAngle = -1 * angleDegrees - 90;
            if(layer.opponent.sprite.position.x > self.lastPoint.x)
                cocosAngle += 180;
            //        [missile setRotation:cocosAngle];
            self.sprite.rotation = cocosAngle;
            
//            CGFloat angle = ccpAngle(layer.opponent.sprite.position, self.sprite.position);
//            //self.lastPoint = targetPoint;
//            self.sprite.rotation = angle+90;
            
            // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
            int distancePixels = (int) (self.speedInPixelsPerSec * kTickLengthSeconds);
//            ccTime actualDuration = (float) distancePixels / speedInPixelsPerSec; //  0.3; //  v = d / t; t = d / v

            //            actualDuration = 0.3;
            // create the actions
            // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
            // ccpNormalize calculates a unit vector given 2 point coordinates,...
            // and gives a hypotenous of length 1 with appropriate x,y
            //            id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(myLayer.player.position,sprite.position)), 10)];
            id actionMove = [CCMoveBy actionWithDuration:kTickLengthSeconds position:ccpMult(ccpNormalize(ccpSub(layer.opponent.sprite.position,self.sprite.position)), distancePixels)];
            // callback to this method again! If the entity has changed it's behavior, then a different case will be implemented
//            id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(takeActions)];
//            [sprite runAction:[CCSequence actions:actionMove, nil]];
            
            [self.sprite runAction:actionMove];
            
            
        }
            break;
        default:
            break;
    }
    
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

/*  // calls made in EntityNode class
-(void)animateTakeDamage:(int)damagePoints
{
}

-(void)animateKill
{
}
*/

-(void)animateExplode:(CGPoint) targetPoint  // animate it exploding
{

}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        self.entityType = kEntityTypeBat;
        
        // set bat's stats
        self.hitPoints = kEntityBatHitPoints;
        self.speedInPixelsPerSec = kEntityBatSpeedPPS;
        
        if(self.owner.uniqueID == 2)
            self.sprite = [CCSprite spriteWithFile:@"batRed.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"batGreen.png"];
        
        self.sprite.position = [coder decodeCGPointForKey:EntityNodePosition];
        
        [self addChild:self.sprite];
    }
    return self;
}

@end

