//
//  Shuriken.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import "Shuriken.h"
#import "GameConstants.h"
#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "SimpleAudioEngine.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "WeaponNode.h"

static int _uniqueIDCounter = 0;

@implementation Shuriken

#pragma mark - Entity overrides

+(int)nextUniqueID  // static function for providing unique integer IDs to each new instance of each particular entity kind
{
    return _uniqueIDCounter++;
}

-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay
{
    if (self = [super initInLayerWithoutCache:layer atSpawnPoint:spawnPoint]) {
        
        self.entityType = kEntityTypeShuriken;
        self.uniqueID = uniqueID;
        self.owner = owner;
        
        // set Shuriken's stats
        self.hitPoints = kEntityShurikenHitPoints;
        self.speedInPixelsPerSec = kEntityShurikenSpeedPPS;
        self.damage = kShurikenDamage;
        self.sprite = [CCSprite spriteWithFile:@"Projectile.png"];
        self.lastPoint = spawnPoint;
        self.sprite.position = self.lastPoint;
        
        id actionStall = [CCActionInterval actionWithDuration:delay];  // DEBUG does this work??
        
        self.sprite.visible = NO;
        
        id actionAppear = [CCCallBlock actionWithBlock:^(void){
            [[SimpleAudioEngine sharedEngine] playEffect:@"shurikenSound.m4a"];
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
        [[SimpleAudioEngine sharedEngine] playEffect:@"shurikenSound.m4a"];
        
        self.entityType = kEntityTypeShuriken;
        self.uniqueID = [Shuriken nextUniqueID];
        self.owner = owner;
        
        // set Shuriken's stats
        self.hitPoints = kEntityShurikenHitPoints;
        self.speedInPixelsPerSec = kEntityShurikenSpeedPPS;
        self.damage = kShurikenDamage;
        self.sprite = [CCSprite spriteWithFile:@"Projectile.png"];
        self.lastPoint = spawnPoint;
        self.sprite.position = self.lastPoint;
        
        // determine the actual targetPoint based on the range of the shuriken
        CGPoint theVector = ccpMult(ccpNormalize(ccpSub(targetPoint,self.sprite.position)), ((float)kShurikenRangeInPixels));
        self.targetPoint = ccpAdd(targetPoint, theVector);

        self.strikingRange = self.speedInPixelsPerSec * kTickLengthSeconds; // distance the weapon can travel in 1 update tick length
        
        [self addChild:self.sprite];
        
        [self cacheStateForEvent:DVEvent_Spawn];
        
        // add ourself to GameCoreLayer's dict to set up for collision detections
        [layer.collidableProjectiles addEntriesFromDictionary:[NSDictionary dictionaryWithObject:self forKey:[NSNumber numberWithInt:self.uniqueID]]];
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
    
}

-(void)animateKill:(CGPoint)killPosition
{
    [super animateKill:killPosition];  // puts any necessary sprint to last location action into the actionsToBePlayed queue
    
//    id actionKill = [CCCallBlock actionWithBlock:^(void){
//        [self animateExplode];
//    }];
//    
//    [self.actionsToBePlayed addObject:actionKill];
}


-(void)collidedWith:(EntityNode*)entityType
{
    // for now, handle collision results in GameCoreLayer, just play a sound and kill self here
    
    [self kill];
    
    /*
    switch (entityType) {
        case kEntityTypeBat:
        case kEntityTypePlayer:
        {
            
        }
            break;
        default:
            break;
    }
     
     */
    
    // if it's nil, nothing happens (could be a collidable surface)
}

-(void)realUpdate
{
    // draw a line between player and last touch
    // send it on a line from player position to new_location
    
    // first, check if we've reached our endpoint, +/- strikeRadius, and if so, kill
    if(ccpDistance(self.sprite.position, self.targetPoint) < self.strikingRange)
    {
        [self kill];
        return;
    }
    
    int distancePixels = (int) (self.speedInPixelsPerSec * kTickLengthSeconds);
    id actionMove = [CCMoveBy actionWithDuration:kTickLengthSeconds position:ccpMult(ccpNormalize(ccpSub(self.targetPoint,self.sprite.position)), distancePixels)];

    [self.sprite runAction:actionMove];
    
}

@end
