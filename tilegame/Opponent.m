//
//  Player2.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import "Opponent.h"

@implementation Opponent

@synthesize opponentSprite, playerID, myLayer, hitPoints, opponentMinionList;

-(id)initWithLayer:(HelloWorldLayer*) layer andPlayerID:(NSString*)plyrID andSpawnAt:(CGPoint) spawnPoint;
{
    self = [super init];
    if(self)
    {
        playerID = plyrID;
        // store the layer we belong to - not sure if this is needed or not
        myLayer = layer;
        
        //        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];  // preload creature sounds
        
        // set Player's initial stats
        self.hitPoints = 1;
        
        opponentSprite = [CCSprite spriteWithFile:@"Player.png"];
        opponentSprite.position = spawnPoint;
        
        [self addChild:opponentSprite];
        // is this enough to display it?
        
        [myLayer addChild:self];
    }
    return self;
}

@end
