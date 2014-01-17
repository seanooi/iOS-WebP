//
//  UIImage+WebP.h
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WebP)

+ (UIImage *)imageFromWebP:(NSString *)filePath;
+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality;
- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;

+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality completion:(void (^)(NSData *result))completionBlock;
+ (void)imageFromWebP:(NSString *)filePath completion:(void (^)(UIImage *result))completionBlock;

@end
