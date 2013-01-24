//
//  Player2.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import "Opponent.h"

@implementation Opponent

@synthesize playerSprite, myLayer, minionsList;

-(id) initWithLayer:(HelloWorldLayer*) layer
{
    self = [super init];
    if(self)
    {
        self.myLayer = layer;
        [layer addChild:self];  // since we are a Node, we can add ourself to the layer
        
        // load the appropriate player sprite here
        
        // setup and run the action here

    }
    return self;
}

@end
