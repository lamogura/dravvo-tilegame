//
//  GameOverScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface GameOverLayer : CCLayerColor
{
    CCLabelTTF* _label;
}
@property (nonatomic, strong) CCLabelTTF *label;
@end



@interface GameOverScene : CCScene
{
    GameOverLayer* _layer;
}
@property (nonatomic, strong) GameOverLayer* layer;
@end
