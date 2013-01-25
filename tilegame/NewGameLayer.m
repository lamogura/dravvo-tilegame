//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NewGameLayer.h"
#import "HelloWorldLayer.h"

@implementation NewGameScene
@synthesize layer = _layer;

-(id) init
{
    if((self = [super init]))
    {
        self.layer = [NewGameLayer node];
        [self addChild:_layer];
    }
    return self;
}

@end

@implementation NewGameLayer

-(id) init
{
    if( (self=[super initWithColor:ccc4(255,255,255,255)] )) {
        
//        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CCMenuItemImage *item1 = [CCMenuItemImage itemWithNormalImage:@"new_game_button.png" selectedImage:nil disabledImage:nil block:^(id sender) {
            [[CCDirector sharedDirector] replaceScene:[HelloWorldLayer scene]];
        }];
        
        //Adding menu items to the CCMenu. Don't forget to include 'nil'
        CCMenu *selectMenu= [CCMenu menuWithItems:item1, nil];
        //Aligning & Adding CCMenu child to the scene
        [selectMenu alignItemsVertically];
        [self addChild:selectMenu];
    }
    return self;
}

+(CCScene *) scene
{
	CCScene *theScene = [CCScene node];
    NewGameLayer *layer = [NewGameLayer node];

	[theScene addChild: layer];
	return theScene;
}

@end