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

-(id)init
{
    if( (self=[super initWithColor:ccc4(0,0,0,255)] )) {
        CCMenuItemImage *loadingItem = [CCMenuItemImage
                                        itemWithNormalImage:@"loading.png"
                                        selectedImage:nil];
        
        CCMenu *menu= [CCMenu menuWithItems:loadingItem, nil];
        
        [menu alignItemsVertically];
        [self addChild:menu];
    }
    return self;
}


+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild:[LoadingLayer node]];
	return scene;
}

@end