//
//  UIImage+WebP.h
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebP/decode.h>
#import <WebP/encode.h>

@interface UIImage (WebP)

+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality __attribute((deprecated("use imageToWebP:quality:alpha:completionBlock:failureBlock: instead")));
+ (UIImage *)imageFromWebP:(NSString *)filePath __attribute((deprecated("use imageFromWebP:filePath:completionBlock:failureBlock: instead")));

+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha preset:(WebPPreset)preset
    completionBlock:(void (^)(NSData *result))completionBlock
       failureBlock:(void (^)(NSError *error))failureBlock;

+ (void)imageFromWebP:(NSString *)filePath
      completionBlock:(void (^)(UIImage *result))completionBlock
         failureBlock:(void (^)(NSError *error))failureBlock;

- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;

@end
