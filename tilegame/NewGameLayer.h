//
//  NewGameScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "DVAPIWrapper.h"

@interface NewGameLayer : CCLayerColor {
    DVAPIWrapper* _apiWrapper;
}
+(CCScene *) scene;
@end

@interface NewGameScene : CCScene
@property (nonatomic, strong) NewGameLayer* layer;
@end




