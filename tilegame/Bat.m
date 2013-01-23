//
//  Bat.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import "Bat.h"

@implementation Bat

-(id)initWithPosition:(CGPoint) position
{
    self = [super init];
    if(self)
    {
        // set bat's stats
        self.hitPoints = 1;
        self.speedInPixelsPerSec = 33;
    
        CCSprite* enemy = [CCSprite spriteWithFile:@"bat.png"];
        enemy.position = position;

        [self addChild:enemy];
    }
    return self;
}

@end
