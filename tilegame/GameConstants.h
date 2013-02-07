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

#define kReplayTickLengthSeconds 0.50  // sampling rate and playback rate 0.50
#define kTickLengthSeconds 0.10  // length of a single tick in seconds (time between mainGameLoop callbacks)
#define kTurnLengthSeconds 10  // length of a players entire turn in seconds, before passing to next player's turn
#define kPlayerOne 1  // for the static Historical Dictionaries indicies contained in the minions / bats class
#define kPlayerTwo 2

#define kNumMelons 5
#define kInitShurikens 10
#define kInitMissiles 10
#define kMaxMelons 5
//#define kTimeStepSeconds 1  // time step for sampling rate and oponnent turn re-play animation rate