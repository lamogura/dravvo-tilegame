//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NewGameLayer.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "DVConstants.h"
#import "CountdownLayer.h"

@implementation NewGameLayer

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [NewGameLayer node]];
	return scene;
}

-(id) init
{
    if(self=[super initWithColor:ccc4(255,255,255,255)])
    {
        DVAPIWrapper *apiWrapper = [[DVAPIWrapper alloc] init];
        
        CCMenuItemImage *newGameItem = [CCMenuItemImage
                                        itemWithNormalImage:@"new_game_button.png"
                                        selectedImage:nil
                                        disabledImage:nil
                                        block:^(id sender) {
            [apiWrapper postCreateNewGameThenCallBlock:^(NSError *error, DVServerGameData *status) {
                if (error != nil) {
                    ULog(@"%@", [error localizedDescription]);
                }
                else {
                    DLog(@"Saving gameID to defaults: %@", status.gameID);
                    [[NSUserDefaults standardUserDefaults] setObject:status.gameID forKey:kCurrentGameIDKey];

                    // In this case, we are the HOST of the new game, so we get playerID = 1, GUEST will get 2
                    CCDirector* director = [CCDirector sharedDirector];
                    CCScene* gameScene = [CoreGameLayer scene:NewGameAsHost];
                    CoreGameLayer* gameLayer = (CoreGameLayer *)[gameScene getChildByTag:kCoreGameLayerTag];

                    [director replaceScene:gameScene];

                    // start our turn
                    CountdownLayer* cdlayer = [[CountdownLayer alloc]
                                               initWithCountdownFrom:3
                                   AndCallBlockWhenCountdownFinished:^(id status) {
                        [gameLayer startRound];
                    }];
                    [gameScene addChild:cdlayer];
                }
            }];
        }];
        
        //Aligning & Adding CCMenu child to the scene
        CCMenu *menu= [CCMenu menuWithItems:newGameItem, nil];
        [menu alignItemsVertically];
        [self addChild:menu];
    }
    return self;
}

@end