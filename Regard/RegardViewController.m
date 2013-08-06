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
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pasteboardChangedNotification:)
     name:UIPasteboardChangedNotification
     object:[UIPasteboard generalPasteboard]];
    
    //[self updateStateFromPlayer:musicPlayer];
    [self categoryChanged:nil];
    [self resultViewChanged:nil];
    
    self.resultWebView.delegate = self;
/*
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
//    press.numberOfTapsRequired = 2;
    press.delegate = self;
 
    [self.resultWebView addGestureRecognizer:press];
 */
}

- (void)pasteboardChangedNotification:(NSNotification*)notification {
    //pasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    NSLog(@"%d", gpBoard.changeCount);
    if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString]) {
        self.resultTextView.text = [gpBoard valueForPasteboardType:@"public.text"];
    }
}
/*
- (void)onLongPress:(id)sender
{
    NSLog(@"onLongPress()");
}
*/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    NSLog(@"webViewDidStartLoad: on thread: %@", [NSThread currentThread]);
    injectedJavascript = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    // do this @selector delay so we minimize the number of times we inject the javascript
    // it seems there are multiple thread that call didfinishload:
//    NSLog(@"webViewDidFinishLoad: on thread: %@", [NSThread currentThread]);
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(injectJavascript:) object:webView];
//    [self performSelector:@selector(injectJavascript:) withObject:webView afterDelay:1];
    //    [self updateTextFromWebView:webView];
}

- (void)injectJavascript:(UIWebView *)webView
{
    if (!injectedJavascript) {
        NSError *err;
        NSString *js = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"js/select" ofType:@"js"] encoding:NSStringEncodingConversionAllowLossy error:&err];
        if (err) {
            NSLog(@"%@", err);
        } else {
            injectedJavascript = YES;
            [webView stringByEvaluatingJavaScriptFromString:js];
            NSLog(@"injected javascript");
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // handle window.location changes...
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            // legit link navigation
        NSLog(@"%@", [request URL]);
    } else if (navigationType == UIWebViewNavigationTypeOther) {
        //NSLog(@"type other: %@", [request URL]);
		if ([[[request URL] scheme] compare:@"regard"] == NSOrderedSame) {
            // get notification of 'selectionchange' event from the dom
			if ([[[request URL] host] compare:@"selectionchange"] == NSOrderedSame) {
                NSLog(@"selectionchange event");
            }
            return NO;
        }
    }
    return YES;
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
    [self.resultWebView stopLoading];
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
//        urlString = [NSString stringWithFormat:@"http://10.1.1.7"];
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
