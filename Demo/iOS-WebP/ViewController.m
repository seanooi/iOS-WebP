//
//  ViewController.m
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+WebP.h"

@interface ViewController ()
{
    IBOutlet UIImageView *normalView;
    IBOutlet UIImageView *convertedView;
    
    IBOutlet UILabel *normalLabel;
    IBOutlet UILabel *convertedLabel;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSString *imageFileName = @"Rosetta.jpg";
    CGFloat quality = 75.0f;
    CGFloat alpha = 0.5f;
    
    NSString *normalImg = [[NSBundle mainBundle] pathForResource:@"Rosetta" ofType:@"jpg"];
    UIImage *demoImage = [[UIImage imageNamed:imageFileName] imageByApplyingAlpha:alpha];
    [normalView setImage:demoImage];
    
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:normalImg error:nil] fileSize];
    [normalLabel setText:[NSString stringWithFormat:@"JPG format file size: %.2f KB", (double)fileSize/1024]];
    
    NSData *webpData = [UIImage imageToWebP:demoImage quality:quality];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *webpPath = [[NSString alloc] initWithString: [paths[0] stringByAppendingPathComponent:@"image.webp"]];
    
    if ([webpData writeToFile:webpPath atomically:YES]) {
        fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:webpPath error:nil] fileSize];
        [convertedLabel setText:[NSString stringWithFormat:@"WEBP format file size: %.2f KB at %.f%% quality", (double)fileSize/1024, quality]];
        
        [convertedView setImage:[UIImage imageFromWebP:webpPath]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
