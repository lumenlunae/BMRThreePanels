//
//  BMRDViewController.h
//  ThreePanels
//
//  Created by Matthew Herz on 1/31/14.
//  Copyright (c) 2014 BiminiRoad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BMRDThreePanelController : UIViewController

@property (nonatomic, assign) BOOL fullscreen;

-(void) addTopViewController:(UIViewController*)controller;
-(void) addMiddleViewController:(UIViewController*)controller;
-(void) addBottomViewController:(UIViewController*)controller;

-(void) makeTopViewFullscreen;
-(void) makeMiddleViewFullscreen;
-(void) makeBottomViewFullscreen;

// subclass
-(void) topViewWillBecomeFullscreen;
-(void) middleViewWillBecomeFullscreen;
-(void) bottomViewWillBecomeFullscreen;

-(void) makeControllerFullScreen:(UIViewController*)controller;
@end

@protocol BMRDThreePanelDelegate <NSObject>

@property (nonatomic, weak) BMRDThreePanelController* panelController;

@optional
-(void) panelControllerWillMinimize;
@end;