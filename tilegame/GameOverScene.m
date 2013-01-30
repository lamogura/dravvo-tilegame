//
//  GameOverScene.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "GameOverScene.h"
#import "CoreGameLayer.h"

@implementation GameOverScene
@synthesize layer = _layer;

-(id) init
{
    if((self = [super init]))
    {
        self.layer = [GameOverLayer node];
        [self addChild:_layer];
    }
    return self;
}


@end

@implementation GameOverLayer
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
                         [CCCallFunc actionWithTarget:self selector:@selector(gameOverDone)],
                         nil]];
        
    }
    return self;
}

- (void)gameOverDone {
    // FIX should show report of points and stats!
    [[CCDirector sharedDirector] replaceScene:[CoreGameLayer scene:DVNewGameAsHost]];  // try re-starting another game automatically
}


@end