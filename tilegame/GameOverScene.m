//
//  GameOverScene.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "GameOverScene.h"
#import "CoreGameLayer.h"
#import "NewGameLayer.h"

@implementation GameOverLayer

+(CCScene *) sceneWithLabelText:(NSString *)pLabelText
{
	CCScene *scene = [CCScene node];
	[scene addChild:
     [[GameOverLayer alloc] initWithLabelText:pLabelText]];
	return scene;
}

-(id) initWithLabelText:(NSString *)pLabelText
{
    if(self=[super initWithColor:ccc4(255,255,255,255)])
    {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CCLabelTTF* label = [CCLabelTTF labelWithString:pLabelText
                                               fontName:@"Arial"
                                               fontSize:32];
        label.color = ccc3(0,0,0);
        label.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:label];
        
        [self runAction:[CCSequence actions:
                         [CCDelayTime actionWithDuration:5],
                         [CCCallFunc actionWithTarget:self selector:@selector(gameOverDone:)],
                         nil]];
    }
    return self;
}

- (void) gameOverDone
{
    // FIX should show report of points and stats!
    [[CCDirector sharedDirector] replaceScene:[NewGameLayer scene]];  // try re-starting another game automatically
}

@end