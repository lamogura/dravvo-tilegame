//
//  RoundFinishedScene.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//

#import "GameOverScene.h"
#import "CoreGameLayer.h"
#import "RoundFinishedScene.h"

@implementation RoundFinishedScene
@synthesize layer = _layer;

-(id) init
{
    if((self = [super init]))
    {
        self.layer = [RoundFinishedLayer node];
        [self addChild:_layer];

        
        // MAYBE here??
        // put all the different minions lists into one big NSMuttableArray
        
        // hand the huge array of strings to the API Wrapper to deal out to the server and player 2
    
    }
    return self;
}


@end

@implementation RoundFinishedLayer
@synthesize label = _label;

-(id) init
{
    if( (self=[super initWithColor:ccc4(255,255,255,255)] )) {
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        self.label = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32];
        _label.color = ccc3(0,0,0);
        _label.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:_label];
        
        [self runAction:[CCSequence actions:
                         [CCDelayTime actionWithDuration:3],
                         [CCCallFunc actionWithTarget:self selector:@selector(nextRound)],
                         nil]];
        
    }
    return self;
}

- (void)nextRound {
    
    [[CCDirector sharedDirector] replaceScene:[CoreGameLayer scene]];
    
}


@end