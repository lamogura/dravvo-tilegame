//
//  RoundFinishedScene.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//

#import "cocos2d.h"
#import "HelloWorldLayer.h"

@interface RoundFinishedLayer : CCLayerColor
{
    CCLabelTTF* _label;
}

@property (nonatomic, strong) HelloWorldLayer* helloWorldLayer;
@property (nonatomic, strong) CCLabelTTF *label;
@end



@interface RoundFinishedScene : CCScene
{
    RoundFinishedLayer* _layer;
}
@property (nonatomic, strong) RoundFinishedLayer* layer;
@end
