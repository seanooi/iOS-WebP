//
//  ViewController.m
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+WebP.h"

//static NSString *imageFileName = @"Rosetta.jpg";
static NSString *imageFileName = @"mn.png";
static CGFloat quality = 75.0f;
static CGFloat alpha = 0.6f;
static BOOL asyncConvert = YES;

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
    
    //NSString *normalImg = [[NSBundle mainBundle] pathForResource:@"Rosetta" ofType:@"jpg"];
    NSString *normalImg = [[NSBundle mainBundle] pathForResource:@"mn" ofType:@"png"];
    UIImage *demoImage = [UIImage imageNamed:imageFileName];
    [normalView setImage:[demoImage imageByApplyingAlpha:alpha]];
    
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:normalImg error:nil] fileSize];
    [normalLabel setText:[NSString stringWithFormat:@"%@ format file size: %.2f KB with alpha: %.2f",[[normalImg pathExtension] uppercaseString] , (double)fileSize/1024, alpha]];
    
    [convertedView setImage:[UIImage imageNamed:@"default.png"]];
    [convertedLabel setText:@"Waiting..."];
    
    if (!asyncConvert) {
        NSData *webPData = [UIImage imageToWebP:demoImage quality:quality];
        [self displayImageWithData:webPData];
    }
    else {
        [UIImage imageToWebP:demoImage quality:quality alpha:alpha preset:WEBP_PRESET_PHOTO completionBlock:^(NSData *result) {
            [self displayImageWithData:result];
        } failureBlock:^(NSError *error) {
            NSLog(@"%@", error.localizedDescription);
        }];
    }
}

- (void)displayImageWithData:(NSData *)webPData
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *webPPath = [paths[0] stringByAppendingPathComponent:@"image.webp"];
    
    if ([webPData writeToFile:webPPath atomically:YES]) {
        uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:webPPath error:nil] fileSize];
        [convertedLabel setText:[NSString stringWithFormat:@"WEBP format file size: %.2f KB at %.f%% quality", (double)fileSize/1024, quality]];
        
        if (!asyncConvert) {
            [convertedView setImage:[UIImage imageWithWebP:webPPath]];
        }
        else {
            [UIImage imageWithWebP:webPPath completionBlock:^(UIImage *result) {
                [convertedView setImage:result];
            }failureBlock:^(NSError *error) {
                NSLog(@"%@", error.localizedDescription);
            }];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
