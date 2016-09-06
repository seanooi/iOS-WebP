//
//  ViewController.m
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import "ViewController.h"
#import <iOS-WebP/UIImage+WebP.h>

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
    
    UIImage *demoImage = [UIImage imageNamed:@"MN"];
    [normalView setImage:[demoImage imageByApplyingAlpha:alpha]];
    
    NSData *demoImageData = UIImageJPEGRepresentation(demoImage, 1.0);
    uint64_t fileSize = [demoImageData length];
    
    [normalLabel setText:[NSString stringWithFormat:@"%@ format file size: %.2f KB with alpha: %.2f", [self contentTypeForImageData:demoImageData] , (double)fileSize/1024, alpha]];
    
    [convertedView setImage:[UIImage imageNamed:@"Default"]];
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

#pragma mark - Helper

- (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"JPEG";
        case 0x89:
            return @"PNG";
        case 0x47:
            return @"GIF";
        case 0x49:
            break;
        case 0x42:
            return @"BMP";
        case 0x4D:
            return @"TIFF";
    }
    
    return nil;
}

@end
