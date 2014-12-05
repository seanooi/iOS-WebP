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

+ (UIImage*)imageWithWebPData:(NSData*)imgData;

+ (UIImage*)imageWithWebP:(NSString*)filePath;

+ (NSData*)imageToWebP:(UIImage*)image quality:(CGFloat)quality;

+ (void)imageToWebP:(UIImage*)image
            quality:(CGFloat)quality
              alpha:(CGFloat)alpha
             preset:(WebPPreset)preset
    completionBlock:(void (^)(NSData* result))completionBlock
       failureBlock:(void (^)(NSError* error))failureBlock;

+ (void)imageToWebP:(UIImage*)image
            quality:(CGFloat)quality
              alpha:(CGFloat)alpha
             preset:(WebPPreset)preset
        configBlock:(void (^)(WebPConfig* config))configBlock
    completionBlock:(void (^)(NSData* result))completionBlock
       failureBlock:(void (^)(NSError* error))failureBlock;

+ (void)imageWithWebP:(NSString*)filePath
      completionBlock:(void (^)(UIImage* result))completionBlock
         failureBlock:(void (^)(NSError* error))failureBlock;

- (UIImage*)imageByApplyingAlpha:(CGFloat)alpha;

@end
