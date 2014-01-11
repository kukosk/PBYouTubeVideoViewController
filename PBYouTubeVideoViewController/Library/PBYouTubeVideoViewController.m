//
//  PBYouTubeVideoViewController.m
//
//  Created by Philippe Bernery on 08/02/13.
//  Copyright (c) 2013 Philippe Bernery. All rights reserved.
//

#import "PBYouTubeVideoViewController.h"


NSString *const PBYouTubePlayerEventReady = @"ready";
NSString *const PBYouTubePlayerEventStateChanged = @"stateChange";
NSString *const PBYouTubePlayerEventPlaybackQualityChanged = @"playbackQualityChange";
NSString *const PBYouTubePlayerEventPlaybackRateChanged = @"playbackRateChange";
NSString *const PBYouTubePlayerEventError = @"error";
NSString *const PBYouTubePlayerEventApiChange = @"apiChange";

const CGFloat YouTubeStandardPlayerWidth = 640;
const CGFloat YouTubeStandardPlayerHeight = 390;


@interface PBYouTubeVideoViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, assign) BOOL firstPageLoaded;

@end


@implementation PBYouTubeVideoViewController

- (id)initWithVideoId:(NSString *)videoId
{
    NSParameterAssert(videoId != nil);

    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.videoId = videoId;
		self.usesDefaultVideoRatio = YES;
    }
    return self;
}

- (void)dealloc
{
    self.webView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.backgroundColor = self.view.backgroundColor;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.firstPageLoaded = NO;
    [self.webView loadHTMLString:[self htmlContent] baseURL:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self updatePlayerSize];
}

#pragma mark - Actions

- (void)play
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"player.playVideo();"];
}

- (void)pause
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"player.pauseVideo();"];
}

- (void)stop
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"player.stopVideo();"];
}

#pragma mark - Accessors

- (void)setUsesDefaultVideoRatio:(BOOL)usesDefaultVideoRatio
{
	BOOL oldUsesDefaultVideoRatio = _usesDefaultVideoRatio;
	_usesDefaultVideoRatio = usesDefaultVideoRatio;
	
	if(oldUsesDefaultVideoRatio != self.usesDefaultVideoRatio)
	{
		if(self.isViewLoaded)
		{
			[self.view setNeedsLayout];
		}
	}
}

- (void)setPlayerSize:(CGSize)playerSize
{
    [self.webView stringByEvaluatingJavaScriptFromString:
            [NSString stringWithFormat:@"player.setSize(%u, %u);",
                            (unsigned int) playerSize.width, (unsigned int) playerSize.height]];
}

- (NSTimeInterval)duration
{
    return [[self.webView stringByEvaluatingJavaScriptFromString:@"player.getDuration();"] doubleValue];
}

- (NSTimeInterval)currentTime
{
    return [[self.webView stringByEvaluatingJavaScriptFromString:@"player.getCurrentTime();"] doubleValue];
}

#pragma mark - Helpers

- (NSString *)htmlContent
{
    NSString *pathToHTML = [[NSBundle mainBundle] pathForResource:@"PBYouTubeVideoView" ofType:@"html"];
    NSAssert(pathToHTML != nil, @"could not find PBYouTubeVideoView.html");

    NSError *error = nil;
    NSString *template = [NSString stringWithContentsOfFile:pathToHTML encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }

    CGSize playerSize = [self playerSize];
    NSString *result = [NSString stringWithFormat:template,
                    [NSString stringWithFormat:@"%.0f", playerSize.width],
                    [NSString stringWithFormat:@"%.0f", playerSize.height],
                    self.videoId];
    return result;
}

- (void)updatePlayerSize
{
    CGSize playerSize = [self playerSize];
    [self setPlayerSize:playerSize];
}

- (CGSize)playerSize
{
	CGSize playerSize = CGSizeZero;
	
	if(self.usesDefaultVideoRatio)
	{
		float heightRatio = self.view.bounds.size.height / YouTubeStandardPlayerHeight;
		float widthRatio = self.view.bounds.size.width / YouTubeStandardPlayerWidth;
		float ratio = MIN(widthRatio, heightRatio);
		
		playerSize = CGSizeMake(YouTubeStandardPlayerWidth * ratio, YouTubeStandardPlayerHeight * ratio);
	}
	else
	{
		playerSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
	}
	
    return playerSize;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request URL].scheme isEqualToString:@"ytplayer"]) {
        NSArray *components = [[request URL] pathComponents];
        if ([components count] > 1) {
            NSString *actionName = components[1];
            NSString *actionData = nil;
            if ([components count] > 2) {
                actionData = components[2];
            }

            if ([actionName isEqualToString:PBYouTubePlayerEventReady] && !self.firstPageLoaded) {
                // The YouTube player is reader meaning it accepts JS commands.
                // The player may not have the right size in some obscure circumstances
                // (especially on iPad). We resize it.
                [self updatePlayerSize];

                self.firstPageLoaded = YES;
            }

            [self.delegate youTubeVideoViewController:self didReceiveEventNamed:actionName eventData:actionData];
        }
        return NO;
    } else {
        return YES;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.delegate youTubeVideoViewController:self didReceiveEventNamed:PBYouTubePlayerEventError eventData:nil];
}

@end
