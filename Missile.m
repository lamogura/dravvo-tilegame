//
//  Missile.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import "Missile.h"
#import "GameConstants.h"
#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "WeaponNode.h"

static int _uniqueIDCounter = 0;

@implementation Missile

#pragma mark - Entity overrides

+(int)nextUniqueID  // static function for providing unique integer IDs to each new instance of each particular entity kind
{
    return _uniqueIDCounter++;
}

-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay
{
    if (self = [super initInLayer:layer atSpawnPoint:spawnPoint]) {
        
        self.entityType = kEntityTypeMissile;
        self.uniqueID = uniqueID;
        self.owner = owner;
        
        // set Missile's stats
        self.hitPoints = kEntityMissileHitPoints;
        self.speedInPixelsPerSec = kEntityMissileSpeedPPS;
        self.damage = kMissileDamage;
        self.sprite = [CCSprite spriteWithFile:@"missile.png"];
        
//        [self setContentSize:self.sprite.boundingBox.size];
        self.lastPoint = spawnPoint;
        self.sprite.position = self.lastPoint;
                
        id actionStall = [CCActionInterval actionWithDuration:delay];  // DEBUG does this work??

        self.sprite.visible = NO;
        
        id actionAppear = [CCCallBlock actionWithBlock:^(void){
            [[SimpleAudioEngine sharedEngine] playEffect:@"missileSound.m4a"];
            self.sprite.visible = YES;
        }];
        
        [self.actionsToBePlayed addObject:actionStall];  // change to this for multiplay
        [self.actionsToBePlayed addObject:actionAppear];
        
        [self addChild:self.sprite];
        
        [self.gameLayer addChild:self];

    }
    return self;
   
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withTargetPoint:(CGPoint)targetPoint ownedBy:(EntityNode *)owner
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint])
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"missileSound.m4a"];
        
        self.entityType = kEntityTypeMissile;
        self.uniqueID = [Missile nextUniqueID];
        self.owner = owner;
        self.targetPoint = targetPoint;
        
        // set Missile's stats
        self.hitPoints = kEntityMissileHitPoints;
        self.speedInPixelsPerSec = kEntityMissileSpeedPPS;
        self.damage = kMissileDamage;
        self.sprite = [CCSprite spriteWithFile:@"missile.png"];

//        [self setContentSize:self.sprite.boundingBox.size];
        self.lastPoint = spawnPoint;
        self.sprite.position = self.lastPoint;
        
        // set the missiles rotation angle
        CGPoint diff = ccpSub(self.targetPoint, self.sprite.position);
        
        float angleRadians = atanf(diff.y / (float)diff.x);
        float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
        float cocosAngle = -1 * angleDegrees - 90;
        if(self.targetPoint.x > self.sprite.position.x)
            cocosAngle += 180;

        self.sprite.rotation = cocosAngle;
        
        [self addChild:self.sprite];
        
        [self cacheStateForEvent:DVEvent_Spawn];
        
        // get it moving from instantiation
        //        [self realUpdate];
        
        [self.gameLayer addChild:self];
        
        self.strikingRange = self.speedInPixelsPerSec * kTickLengthSeconds; // distance the weapon can travel in 1 update tick length
        
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
    
    // DON'T cache an explode, will be handled locally
    [self realExplode];
}

-(void)animateKill:(CGPoint)killPosition
{
    [super animateKill:killPosition];  // puts any necessary sprint to last location action into the actionsToBePlayed queue
    
    id actionKill = [CCCallBlock actionWithBlock:^(void){
        [self animateExplode];
    }];
    
    [self.actionsToBePlayed addObject:actionKill];
}

-(void)realUpdate
{
    // calculate duration of how far Missile can fly during kTickLengthSeconds time
    // travel there and then do nothing until the next update is called
    
    // draw a line between player and last touch
    // send it on a line from player position to new_location

    if(ccpDistance(self.sprite.position, self.targetPoint) < self.strikingRange)
    {        
        // remove the missile image and then explode (in kill)
        [self kill];   // remove ourselves and cache
        return;
    }
    
    int distancePixels = (int) (self.speedInPixelsPerSec * kTickLengthSeconds);
    id actionMove = [CCMoveBy actionWithDuration:kTickLengthSeconds position:ccpMult(ccpNormalize(ccpSub(self.targetPoint,self.sprite.position)), distancePixels)];

    [self.sprite runAction:actionMove];
    
}

// collisions detection happens in CoreGameLayer, here we just show image, play sound, remove self with delayed callback
-(void)realExplode  // should also remove us from the layer
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"missileExplode.m4a"];
    
    // explode, killing anything in 4 box radius
    CCSprite* explosion = [CCSprite spriteWithFile:@"nuked.png"];
    explosion.position = self.sprite.position;
    [self addChild:explosion];
        
    // make a rectangle that is 2*2 tiles wide, kill everything collided with it (including destructable tiles from tilemap)
    // anything within 2 * the explosion images bounding box gets killed (explosion will expand to 2 times size)
    CGRect explosionArea = CGRectMake(explosion.position.x - (explosion.contentSize.width/2)*2, explosion.position.y - (explosion.contentSize.height/2)*2, explosion.contentSize.width*2, explosion.contentSize.height*2);

    [(CoreGameLayer*)self.gameLayer explosionAt:self.sprite.position effectingArea:explosionArea infilctingDamage:kMissileDamage weaponID:self.uniqueID];

    id scaleUpAction =  [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:2.0 scaleY:2.5] rate:2.0];
    
    id actionRemoveSelf = [CCCallBlock actionWithBlock:^(void){
        [self removeChild:explosion cleanup:YES];
    }];
    
    [explosion runAction:[CCSequence actionOne:scaleUpAction two:actionRemoveSelf]];
    
}

// can only be called internally, not cached or referred to in CoreGameLayer playback loop
-(void)animateExplode
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"missileExplode.m4a"];
    
    // explode, killing anything in 4 box radius
    CCSprite* explosion = [CCSprite spriteWithFile:@"nuked.png"];
    explosion.position = self.sprite.position;
    [self addChild:explosion];
    
    // make a rectangle that is 2*2 tiles wide, kill everything collided with it (including destructable tiles from tilemap)
    // anything within 2 * the explosion images bounding box gets killed (explosion will expand to 2 times size)
//    CGRect explosionArea = CGRectMake(explosion.position.x - (explosion.contentSize.width/2)*2, explosion.position.y - (explosion.contentSize.height/2)*2, explosion.contentSize.width*2, explosion.contentSize.height*2);
//    
//    [(CoreGameLayer*)self.gameLayer explosionAt:self.sprite.position effectingArea:explosionArea infilctingDamage:kMissileDamage weaponID:self.uniqueID];
    
    id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:2.0 scaleY:2.5] rate:2.0];
    
    id actionRemoveSelf = [CCCallBlock actionWithBlock:^(void){
        [self removeChild:explosion cleanup:YES];
    }];
    
    [explosion runAction:[CCSequence actionOne:scaleUpAction two:actionRemoveSelf]];  // try running actions immediately on callback
    
}


@end
