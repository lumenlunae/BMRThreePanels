//
//  BMRDViewController.m
//  ThreePanels
//
//  Created by Matthew Herz on 1/31/14.
//  Copyright (c) 2014 BiminiRoad. All rights reserved.
//

#import "BMRDThreePanelController.h"

@interface BMRDThreePanelController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIViewController* topController;
@property (nonatomic, strong) UIViewController* middleController;
@property (nonatomic, strong) UIViewController* bottomController;

@property (nonatomic, assign) CGFloat topViewHeight;
@property (nonatomic, assign) CGFloat middleViewHeight;
@property (nonatomic, assign) CGFloat bottomViewHeight;
@property (nonatomic, assign) CGFloat viewOverlapBuffer;

@property (nonatomic, weak) UIView* activePanningView;
@property (nonatomic, assign) CGRect activePanningViewOriginRect;
@property (nonatomic, assign) CGFloat panHeightThreshold;
@property (nonatomic, assign) BOOL fullscreen;
@end

@implementation BMRDThreePanelController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];

    
    UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];
    
    self.viewOverlapBuffer = 80;
    self.fullscreen = NO;
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGFloat thirdHeight = nearbyintf(self.view.frame.size.height/3);
    CGFloat roundedHeight = 3*thirdHeight;
    CGFloat buffer = 0;
    if (roundedHeight < self.view.frame.size.height) {
        buffer = self.view.frame.size.height - roundedHeight;
    }
    
    CGFloat panels = 140;
    self.topViewHeight = panels;
    self.middleViewHeight = self.view.frame.size.height - panels - panels;
    self.bottomViewHeight = panels;

    [self resetViewFrames];
    self.panHeightThreshold = self.view.frame.size.height - thirdHeight;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout
-(void) resetViewFrames
{
    self.topController.view.frame = self.topViewControllerFrame;
    self.middleController.view.frame = self.middleViewControllerFrame;
    self.bottomController.view.frame = self.bottomViewControllerFrame;
}

-(void) setTopViewHeight:(CGFloat)topViewHeight
{
    _topViewHeight = topViewHeight;
    self.topController.view.frame = self.topViewControllerFrame;
}

-(void) setMiddleViewHeight:(CGFloat)middleViewHeight
{
    _middleViewHeight = middleViewHeight;
    self.middleController.view.frame = self.middleViewControllerFrame;
}

-(void) setBottomViewHeight:(CGFloat)bottomViewHeight
{
    _bottomViewHeight = bottomViewHeight;
    self.bottomController.view.frame = self.bottomViewControllerFrame;
}

-(CGRect) topViewControllerFrame
{
    // only show the bottom portion of topViewHeight
    CGFloat totalHeight = self.view.frame.size.height - self.viewOverlapBuffer;
    CGFloat y = totalHeight - self.topViewHeight;
    return CGRectMake(0, -y, self.view.frame.size.width, totalHeight);
}

-(CGRect) middleViewControllerFrame
{
    return CGRectMake(0, self.topViewHeight, self.view.frame.size.width, self.middleViewHeight);
}

-(CGRect) bottomViewControllerFrame
{
    CGFloat totalHeight = self.view.frame.size.height - self.viewOverlapBuffer;

    return CGRectMake(0, self.topViewHeight + self.middleViewHeight, self.view.frame.size.width, totalHeight);
}

#pragma mark - Management
-(void) addChildViewController:(UIViewController *)childController
{
    [super addChildViewController:childController];
    [self.view addSubview:childController.view];
    [childController didMoveToParentViewController:self];
}
-(void) addTopViewController:(UIViewController *)controller
{
    _topController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.topViewControllerFrame;
}

-(void) addMiddleViewController:(UIViewController *)controller
{
    _middleController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.middleViewControllerFrame;
}

-(void) addBottomViewController:(UIViewController *)controller
{
    _bottomController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.bottomViewControllerFrame;
}



#pragma mark - Gestures
-(BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        if (self.fullscreen) {
            return NO;
        }
        
        UIPanGestureRecognizer* pan = (UIPanGestureRecognizer*)gestureRecognizer;
        CGPoint translation = [pan translationInView:pan.view];
        if (ABS(translation.y) > ABS(translation.x)) {
            return YES;
        }
    } else if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        if (self.fullscreen) {
            return YES;
        }

    }
    return NO;
}

#pragma mark - Tap
-(void) tapAction:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [recognizer locationInView:recognizer.view];
        if (!CGRectContainsPoint(self.activePanningView.frame, point)) {
            [self resetPanningView];
        }
    }
}

#pragma mark - Pan
-(void) panAction:(UIPanGestureRecognizer*)recognizer
{
    CGPoint point = [recognizer locationInView:recognizer.view];
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (point.y < self.topViewHeight) {
            self.activePanningView = self.topController.view;
            self.activePanningViewOriginRect = self.topViewControllerFrame;
            
        } else if (point.y > self.topViewHeight + self.middleViewHeight) {
            self.activePanningView = self.bottomController.view;
            self.activePanningViewOriginRect = self.bottomViewControllerFrame;
        } else {
            self.activePanningView = nil;
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            return;
        }
        [self.activePanningView.superview bringSubviewToFront:self.activePanningView];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        [self updatePanningViewWithTranslation:translation];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed) {
        [self resetPanningView];
        
    }
}

-(void) updatePanningViewWithTranslation:(CGPoint)translation
{
    CGRect panRect = CGRectOffset(self.activePanningViewOriginRect, 0, translation.y);
    CGRect intersectRect = CGRectIntersection(self.activePanningView.frame, self.view.frame);
    // prevent dragging too far
    if (intersectRect.size.height < self.view.frame.size.height) {
        self.activePanningView.frame = panRect;
        CGFloat percent = intersectRect.size.height / self.view.frame.size.height;
        [self updateOtherViewsWithPercentageHidden:percent];
    } else {
    }
}

-(void) updateOtherViewsWithPercentageHidden:(CGFloat)percent
{
    //percent = 1 - percent;
    CGFloat percentDiff;
    if (self.activePanningView == self.topController.view) {
        percentDiff = (self.viewOverlapBuffer + self.topViewHeight) / self.view.frame.size.height;
    } else {
        percentDiff = (self.viewOverlapBuffer + self.bottomViewHeight) / self.view.frame.size.height;
    }
    CGFloat maxPercent = 1 - (self.viewOverlapBuffer/self.view.frame.size.height);
    percent = percent - percentDiff;
    percent = MAX(MIN(percent, maxPercent), 0);
    
    CGFloat offset = self.view.frame.size.height * percent;
    if (self.activePanningView == self.bottomController.view) {
        // pushing everything up
        offset = -offset;
    }
   
    CGFloat alpha = 1 - percent;
    if (self.activePanningView == self.topController.view) {
        self.bottomController.view.frame = CGRectOffset(self.bottomViewControllerFrame, 0, offset);
        self.bottomController.view.alpha = alpha;
    } else {
        self.topController.view.frame = CGRectOffset(self.topViewControllerFrame, 0, offset);
        self.topController.view.alpha = alpha;
    }
        
    self.middleController.view.frame = CGRectOffset(self.middleViewControllerFrame, 0, offset);
    self.middleController.view.alpha = alpha;
}

-(void) resetPanningView
{
    CGRect intersectRect = CGRectIntersection(self.activePanningView.frame, self.view.frame);
    if (!self.fullscreen && intersectRect.size.height > self.panHeightThreshold) {
        // go full screen
        self.fullscreen = YES;
        CGPoint fullscreenOrigin;
        if (self.activePanningView == self.topController.view) {
            fullscreenOrigin = CGPointMake(0, 0);
        } else {
            fullscreenOrigin = CGPointMake(0, self.viewOverlapBuffer);
        }
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:-10 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.activePanningView.frame = CGRectMake(fullscreenOrigin.x, fullscreenOrigin.y, self.activePanningView.frame.size.width, self.activePanningView.frame.size.height);
            [self updateOtherViewsWithPercentageHidden:1];
        } completion:^(BOOL finished) {
            
        }];

    } else {
        self.fullscreen = NO;
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:-10 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.activePanningView.frame = self.activePanningViewOriginRect;
            [self updateOtherViewsWithPercentageHidden:0];
        } completion:^(BOOL finished) {
            
        }];
    }
}
@end
