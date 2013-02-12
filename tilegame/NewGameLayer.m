//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NewGameLayer.h"
#import "CoreGameLayer.h"
#import "CountdownLayer.h"

@implementation NewGameLayer

+(CCScene *) sceneWithBlockCalledOnNewGameClicked:(void (^)(id sender))block
{
	CCScene *scene = [CCScene node];
	[scene addChild: [[NewGameLayer alloc] initWithBlockCalledOnNewGameClicked:block]];
	return scene;
}

-(id) initWithBlockCalledOnNewGameClicked:(void (^)(id sender))block
{
    if(self=[super initWithColor:ccc4(255,255,255,255)])
    {
        CCMenuItemImage *newGameItem = [CCMenuItemImage
                                        itemWithNormalImage:@"new_game_button.png"
                                        selectedImage:nil
                                        disabledImage:nil
                                        block:block];
        
        //Aligning & Adding CCMenu child to the scene
        CCMenu *menu= [CCMenu menuWithItems:newGameItem, nil];
        [menu alignItemsVertically];
        [self addChild:menu];
    }
    return self;
}

@end