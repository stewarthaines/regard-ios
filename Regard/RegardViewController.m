//
//  RegardViewController.m
//  Regard
//
//  Created by Stewart Haines on 15/07/12.
//  Copyright (c) 2012 RobotInaBox. All rights reserved.
//

#import "RegardViewController.h"

@interface RegardViewController ()

@end

@implementation RegardViewController

@synthesize titleLabel = _titleLabel;
@synthesize albumImageView, resultWebView, categorySegmentedControl, resultTextView, resultSegmentedControl;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    [notificationCenter
     addObserver: self
     selector:    @selector (handle_NowPlayingItemChanged:)
     name:        MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:      musicPlayer];
    
    [notificationCenter
     addObserver: self
     selector:    @selector (handle_PlaybackStateChanged:)
     name:        MPMusicPlayerControllerPlaybackStateDidChangeNotification
     object:      musicPlayer];
    
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    //[self updateStateFromPlayer:musicPlayer];
    [self categoryChanged:nil];
    [self resultViewChanged:nil];
    
    self.resultWebView.delegate = self;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTextFromWebView:) object:webView];
    [self performSelector:@selector(updateTextFromWebView:) withObject:webView afterDelay:0.3];
//    [self updateTextFromWebView:webView];
}

- (void)updateTextFromWebView:(UIWebView *)webView
{
    // grab the content using the dom selector specified for the loaded url
/*    NSString *text;
    if ([self.category isEqualToString:@"tab"]) {
        text = [webView stringByEvaluatingJavaScriptFromString:@"$($('.tb_ct pre')[1]).html()"];
    } else if ([self.category isEqualToString:@"chords"]) {
        text = [webView stringByEvaluatingJavaScriptFromString:@"$($('.tb_ct pre')[1]).html()"];
    } else if ([self.category isEqualToString:@"lyrics"]) {
        text = [webView stringByEvaluatingJavaScriptFromString:@"jQuery(jQuery('#main div')[8]).html()"];
    }
    NSLog(@"%@", text);
    self.resultTextView.text = text;*/
}

- (void)updateStateFromPlayer:(MPMusicPlayerController *)playerController
{
    MPMusicPlayerController *player = playerController;
    if (!player) player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaItem *item = [player nowPlayingItem];
    if (item) {
        // Update the UI (artwork, song name, volume indicator, etc.)
        //        to reflect the iPod state
        NSString *itemTitle = [item valueForProperty:MPMediaItemPropertyTitle];
        NSString *itemArtist = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
        [self.titleLabel setText:[NSString stringWithFormat:@"%@ - %@", itemTitle, itemArtist]];
        
        MPMediaItemArtwork *artwork = [item valueForProperty: MPMediaItemPropertyArtwork];
        UIImage *artworkImage = [artwork imageWithSize: self.view.bounds.size];
        
        if (artworkImage) {
            albumImageView.image = artworkImage;
        } else {
            albumImageView.image = [UIImage imageNamed: @"noArtwork.png"];
        }
        
        // do the query for web results
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestResultsForItem:) object:item];
        [self performSelector:@selector(requestResultsForItem:) withObject:item afterDelay:0.1];
//        [self requestResultsForItem:item];
    }
}

- (void)requestResultsForItem:(MPMediaItem *)item
{
    NSString *urlString;
    if ([self.category isEqualToString:@"lyrics"]) {
        NSString *artist = [[[[item valueForProperty:MPMediaItemPropertyArtist] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSString *title = [[[[item valueForProperty:MPMediaItemPropertyTitle] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        urlString = [NSString stringWithFormat:@"http://www.azlyrics.com/lyrics/%@/%@.html", artist, title];
    } else if ([self.category isEqualToString:@"chords"]) {
        NSString *artist = [[[[item valueForProperty:MPMediaItemPropertyArtist] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSString *title = [[[[item valueForProperty:MPMediaItemPropertyTitle] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSString *artistIndex = [artist substringToIndex:1];
        urlString = [NSString stringWithFormat:@"http://tabs.ultimate-guitar.com/%@/%@/%@_crd.htm", artistIndex, artist, title];
    } else if ([self.category isEqualToString:@"tab"]) {
        NSString *artist = [[[[item valueForProperty:MPMediaItemPropertyArtist] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSString *title = [[[[item valueForProperty:MPMediaItemPropertyTitle] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        NSString *artistIndex = [artist substringToIndex:1];
        urlString = [NSString stringWithFormat:@"http://tabs.ultimate-guitar.com/%@/%@/%@_tab.htm", artistIndex, artist, title];
    }
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSLog(@"%@", url);
    [resultWebView stopLoading];
    [resultWebView loadRequest:request];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name:           MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:         musicPlayer];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name:           MPMusicPlayerControllerPlaybackStateDidChangeNotification
     object:         musicPlayer];
    
    [musicPlayer endGeneratingPlaybackNotifications];
}

- (void)handle_NowPlayingItemChanged:(NSNotification *)notification
{
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [self updateStateFromPlayer:musicPlayer];
}

- (void)handle_PlaybackStateChanged:(NSNotification *)notification
{
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [self updateStateFromPlayer:musicPlayer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)resultViewChanged:(id)sender
{
    NSInteger index = self.resultSegmentedControl.selectedSegmentIndex;
    switch (index) {
        case 0:
//            self.category = @"chords";
//            [self updateStateFromPlayer:[MPMusicPlayerController iPodMusicPlayer]];
            self.resultTextView.hidden = YES;
            self.resultWebView.hidden = NO;
            break;
        default:
            self.resultTextView.hidden = NO;
            self.resultWebView.hidden = YES;
            break;
    }
    [self updateTextFromWebView:self.resultWebView];
}

- (IBAction)categoryChanged:(id)sender
{
    NSInteger index = self.categorySegmentedControl.selectedSegmentIndex;
    switch (index) {
        case 0:
            self.category = @"chords";
            [self updateStateFromPlayer:[MPMusicPlayerController iPodMusicPlayer]];
            break;
        case 1:
            self.category = @"lyrics";
            [self updateStateFromPlayer:[MPMusicPlayerController iPodMusicPlayer]];
            break;
        case 2:
            self.category = @"tab";
            [self updateStateFromPlayer:[MPMusicPlayerController iPodMusicPlayer]];
            break;
        default:
            break;
    }
}

@end
