//
//  BMRDViewController.m
//  ThreePanels
//
//  Created by Matthew Herz on 1/31/14.
//  Copyright (c) 2014 BiminiRoad. All rights reserved.
//

#import "BMRDThreePanelController.h"

@interface BMRDThreePanelController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIViewController<BMRDThreePanelDelegate>* topController;
@property (nonatomic, strong) UIViewController<BMRDThreePanelDelegate>* middleController;
@property (nonatomic, strong) UIViewController<BMRDThreePanelDelegate>* bottomController;

@property (nonatomic, assign) CGFloat topViewHeight;
@property (nonatomic, assign) CGFloat middleViewHeight;
@property (nonatomic, assign) CGFloat bottomViewHeight;
@property (nonatomic, assign) CGFloat viewOverlapBuffer;

@property (nonatomic, strong) UIView* backShadowView;
@property (nonatomic, weak) UIView* activePanningView;
@property (nonatomic, assign) CGRect activePanningViewOriginRect;
@property (nonatomic, assign) CGFloat panHeightThreshold;

@property (nonatomic, strong) UITapGestureRecognizer* tapRecognizer;

@property (nonatomic, assign) BOOL viewFramesInitialized;
@end

@implementation BMRDThreePanelController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];

    
    UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    self.tapRecognizer.delegate = self;
    self.tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    self.viewOverlapBuffer = 80;
    self.fullscreen = NO;
    
    self.backShadowView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.backShadowView];
    self.backShadowView.backgroundColor = [UIColor blackColor];
    self.backShadowView.alpha = 0;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout
-(void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!self.viewFramesInitialized) {
        [self setupViewFrames];
        self.viewFramesInitialized = YES;
    }
}

-(void) setupViewFrames
{
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
    self.panHeightThreshold = self.view.frame.size.height / 2;
}

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
-(void) addTopViewController:(UIViewController<BMRDThreePanelDelegate>*)controller
{
    _topController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.topViewControllerFrame;
    
    id<BMRDThreePanelDelegate> delegate = (id)controller;
    delegate.panelController = self;
}

-(void) addMiddleViewController:(UIViewController<BMRDThreePanelDelegate>*)controller
{
    _middleController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.middleViewControllerFrame;
    
    id<BMRDThreePanelDelegate> delegate = (id)controller;
    delegate.panelController = self;
}

-(void) addBottomViewController:(UIViewController<BMRDThreePanelDelegate>*)controller
{
    _bottomController = controller;
    [self addChildViewController:controller];
    controller.view.frame = self.bottomViewControllerFrame;
    
    id<BMRDThreePanelDelegate> delegate = (id)controller;
    delegate.panelController = self;
}

-(void) makeTopViewFullscreen
{
    if (self.activePanningView == self.topController.view && self.fullscreen) {
        return;
    }
    self.activePanningView = self.topController.view;
    self.activePanningViewOriginRect = self.topViewControllerFrame;
    [self makeViewFullscreen];
}

-(void) makeMiddleViewFullscreen
{
    if (self.activePanningView == self.middleController.view && self.fullscreen) {
        return;
    }
    self.activePanningView = self.middleController.view;
    self.activePanningViewOriginRect = self.middleViewControllerFrame;
    
    [self makeViewFullscreen];
}

-(void) makeBottomViewFullscreen
{
    if (self.activePanningView == self.bottomController.view && self.fullscreen) {
        return;
    }
    self.activePanningView = self.bottomController.view;
    self.activePanningViewOriginRect = self.bottomViewControllerFrame;
    [self makeViewFullscreen];
}

-(void) makeViewFullscreen
{
    CGPoint fullscreenOrigin;
    if (self.activePanningView == self.topController.view) {
        fullscreenOrigin = CGPointMake(0, 0);
    } else if (self.activePanningView == self.middleController.view) {
        fullscreenOrigin = CGPointMake(0, nearbyintf(self.viewOverlapBuffer/2));
    } else {
        fullscreenOrigin = CGPointMake(0, self.viewOverlapBuffer);
    }
    
    self.fullscreen = YES;
    CGFloat duration = MAX(MIN(0.6f * (fullscreenOrigin.y / self.activePanningView.frame.origin.y), 0.6), 0.2);
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:-10 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGFloat height = self.activePanningView.frame.size.height;
        if (self.activePanningView == self.middleController.view) {
            height = nearbyintf(self.view.frame.size.height - self.viewOverlapBuffer);
        }
        self.activePanningView.frame = CGRectMake(fullscreenOrigin.x, fullscreenOrigin.y, self.activePanningView.frame.size.width, height);
        [self updateOtherViewsWithPercentageHidden:1];
    } completion:^(BOOL finished) {
        [self viewControllerWillBecomeFullscreen];
    }];
}

#pragma mark - Gestures
-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

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
        return NO;
    } else if (gestureRecognizer == self.tapRecognizer) {
        
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        if (self.fullscreen) {
            if (!CGRectContainsPoint(self.activePanningView.frame, point)) {
                return YES;
            }
        } else {
            return YES;
        }
        return NO;
    }
    return YES;
}

-(void) setActivePanningView:(UIView *)activePanningView
{
    _activePanningView = activePanningView;
    [self.activePanningView.superview bringSubviewToFront:self.activePanningView];
    [self.view insertSubview:self.backShadowView belowSubview:self.activePanningView];
}

#pragma mark - Tap
-(void) tapAction:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.fullscreen) {
            [self resetPanningView];
        } else {
            CGPoint point = [recognizer locationInView:recognizer.view];
            if (CGRectContainsPoint(self.topController.view.frame, point)) {
                [self makeTopViewFullscreen];
            } else if (CGRectContainsPoint(self.bottomController.view.frame, point)) {
                [self makeBottomViewFullscreen];
            }
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
   
    if (self.activePanningView == self.topController.view) {
        self.bottomController.view.frame = CGRectOffset(self.bottomViewControllerFrame, 0, offset);
    } else if (self.activePanningView == self.bottomController.view) {
        self.topController.view.frame = CGRectOffset(self.topViewControllerFrame, 0, offset);

    }
    if (self.activePanningView != self.middleController.view) {
        self.middleController.view.frame = CGRectOffset(self.middleViewControllerFrame, 0, offset);
    }
        
    
    self.backShadowView.alpha = percent;
}

-(void) resetPanningView
{
    CGRect intersectRect = CGRectIntersection(self.activePanningView.frame, self.view.frame);
    if (!self.fullscreen && intersectRect.size.height > self.panHeightThreshold) {
        // go full screen
        self.fullscreen = YES;
        [self makeViewFullscreen];
    } else {
        self.fullscreen = NO;
        [self viewControllerWillMinimize];
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:-10 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.activePanningView.frame = self.activePanningViewOriginRect;
            [self updateOtherViewsWithPercentageHidden:0];
        } completion:^(BOOL finished) {
            
        }];
    }
}


-(void) viewControllerWillMinimize
{
    self.tapRecognizer.cancelsTouchesInView = NO;
    [self.activePanningView endEditing:YES];
    
    if (self.activePanningView == self.topController.view) {
        if ([self.topController respondsToSelector:@selector(panelControllerWillMinimize)]) {
            [self.topController panelControllerWillMinimize];
        }
    } else if (self.activePanningView == self.middleController.view) {
        if ([self.middleController respondsToSelector:@selector(panelControllerWillMinimize)]) {
            [self.middleController panelControllerWillMinimize];
        }
    } else if (self.activePanningView == self.bottomController.view) {
        if ([self.bottomController respondsToSelector:@selector(panelControllerWillMinimize)]) {
            [self.bottomController panelControllerWillMinimize];
        }
    }
    
}

#pragma mark - Subclass Hooks
-(void) viewControllerWillBecomeFullscreen
{
    self.tapRecognizer.cancelsTouchesInView = YES;
    if (self.activePanningView == self.topController.view) {
        [self topViewWillBecomeFullscreen];
    } else if (self.activePanningView == self.middleController.view) {
        [self middleViewWillBecomeFullscreen];
    } else if (self.activePanningView == self.bottomController.view) {
        [self bottomViewWillBecomeFullscreen];
    }
}

-(void) topViewWillBecomeFullscreen
{
    if ([self.topController respondsToSelector:@selector(panelControllerWillMaximize)]) {
        [self.topController panelControllerWillMaximize];
    }
}

-(void) middleViewWillBecomeFullscreen
{
    if ([self.middleController respondsToSelector:@selector(panelControllerWillMaximize)]) {
        [self.middleController panelControllerWillMaximize];
    }
}

-(void) bottomViewWillBecomeFullscreen
{
    if ([self.bottomController respondsToSelector:@selector(panelControllerWillMaximize)]) {
        [self.bottomController panelControllerWillMaximize];
    }
}

-(void) makeControllerFullScreen:(UIViewController *)controller
{
    if (controller == self.topController) {
        [self makeTopViewFullscreen];
    } else if (controller == self.middleController) {
        [self makeMiddleViewFullscreen];
    } else {
        [self makeBottomViewFullscreen];
    }
}

@end

