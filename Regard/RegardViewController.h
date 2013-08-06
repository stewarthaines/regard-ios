//
//  RegardViewController.h
//  Regard
//
//  Created by Stewart Haines on 15/07/12.
//  Copyright (c) 2012 RobotInaBox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface RegardViewController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL injectedJavascript;
}
@property (nonatomic, strong) IBOutlet NSString *category;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *albumImageView;
@property (nonatomic, strong) IBOutlet UIWebView *resultWebView;
@property (nonatomic, strong) IBOutlet UITextView *resultTextView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *categorySegmentedControl;
@property (nonatomic, strong) IBOutlet UISegmentedControl *resultSegmentedControl;

- (void)updateStateFromPlayer:(MPMusicPlayerController *)player;
- (void)requestResultsForItem:(MPMediaItem *)item;
- (IBAction)categoryChanged:(id)sender;
- (IBAction)resultViewChanged:(id)sender;

@end
