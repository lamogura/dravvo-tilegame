//
//  LoadingScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "LoadingLayer.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation LoadingLayer

-(id) init
{
    if( (self=[super initWithColor:ccc4(0,0,0,255)] )) {
        self->_apiWrapper = [[DVAPIWrapper alloc] init];

        CCMenuItemImage *loadingItem = [CCMenuItemImage
                                        itemWithNormalImage:@"loading.png"
                                        selectedImage:nil];
        
        CCMenu *menu= [CCMenu menuWithItems:loadingItem, nil];
        
        [menu alignItemsVertically];
        [self addChild:menu];
        
        [self->_apiWrapper getGameStatusThenCallBlock:^(NSError *error, DVServerGameData *gameData) {
            //TODO: update game with the game status
            if (error != nil) {
                ULog(@"%@", [error localizedDescription]);
            }
            else {
                DLog(@"Sucessfully got status for gameID: %@", gameData.gameID);
                // now instantiate another layer but this time with the dict to load the opponent's last turn
                [CoreGameLayer setServerGameData:gameData];  // store the current update in GameCoreLayer's static for safe keeping
                [[CCDirector sharedDirector] replaceScene:[CoreGameLayer scene:DVBeginNextTurn]];
            }
        }];
    }
    return self;
}

- (void) dealloc {
    self->_apiWrapper = nil;
}

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [LoadingLayer node]];
	return scene;
}

@end