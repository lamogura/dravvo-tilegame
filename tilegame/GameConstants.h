//
//  gameConstants.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/21/13.
//
//


// ChangeableObject Name Constants (used as key for the historical dictionary)
#define kDVChangeableObjectName_bat @"bat"
//#define kDVChangeableObjectName_player @"player"
//#define kDVChangeableObjectName_opponent @"opponent"

#define kReplayTickLengthSeconds 0.25  // sampling rate and playback rate 0.50
#define kTickLengthSeconds 0.50  // length of a single tick in seconds (time between mainGameLoop callbacks)
#define kTurnLengthSeconds 5.0  // length of a players entire turn in seconds, before passing to next player's turn

#define kCountDownFrom 2

#define kNumMelons 5
#define kInitShurikens 10
#define kInitMissiles 10
#define kMaxMelons 5
//#define kTimeStepSeconds 1  // time step for sampling rate and oponnent turn re-play animation rate