//
//  UIImage+WebP.m
//  iOS-WebP
//
//  Created by Sean Ooi on 12/21/13.
//  Copyright (c) 2013 Sean Ooi. All rights reserved.
//

#import "UIImage+WebP.h"
#import <WebP/decode.h>
#import <WebP/encode.h>

static void free_image_data(void *info, const void *data, size_t size)
{
    if(info != NULL)
        WebPFreeDecBuffer(&(((WebPDecoderConfig *)info)->output));
    else
        free((void *)data);
}

@implementation UIImage (WebP)

+ (UIImage *)imageFromWebP:(NSString *)filePath
{
    NSAssert(filePath != nil, @"imageFromWebP: filepath cannot be nil");
    
    NSError *error = nil;;
    NSData *imgData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if(error != nil) {
        NSLog(@"imageFromWebP: error: %@", error.localizedDescription);
    }
    
    int width = 0, height = 0;
    WebPGetInfo([imgData bytes], [imgData length], &width, &height);
    
    uint8_t *data = WebPDecodeRGBA([imgData bytes], [imgData length], &width, &height);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, width * height * 4, free_image_data);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
        
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    return result;
}

+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality
{
    NSAssert(image != nil, @"imageToWebP:quality: image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality: quality has to be [0, 100]");
    
    CGImageRef webPImageRef = image.CGImage;
    size_t webPBytesPerRow = CGImageGetBytesPerRow(webPImageRef);
    size_t webPBitsPerComponent = CGImageGetBitsPerComponent(webPImageRef);
    CGColorSpaceRef webPColorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo webPBitmapInfo = CGImageGetAlphaInfo(webPImageRef);

    size_t webPImageWidth = CGImageGetWidth(webPImageRef);
    size_t webPImageHeight = CGImageGetHeight(webPImageRef);
    
    CGDataProviderRef webPDataProviderRef = CGImageGetDataProvider(webPImageRef);
    CFDataRef webPImageDatRef = CGDataProviderCopyData(webPDataProviderRef);
    
    uint8_t *webPImageData = (uint8_t *)CFDataGetBytePtr(webPImageDatRef);
    uint8_t *webPOutput;
    
    CGContextRef context = CGBitmapContextCreate(webPImageData, webPImageWidth, webPImageHeight, webPBitsPerComponent, webPBytesPerRow, webPColorSpaceRef, (CGBitmapInfo)webPBitmapInfo);
    void *data = CGBitmapContextGetData(context);
    
    size_t encodedData;
    
    if(webPBitmapInfo == kCGImageAlphaNoneSkipLast)
        encodedData = WebPEncodeRGBA(data, (int)webPImageWidth, (int)webPImageHeight, (int)webPBytesPerRow, quality, &webPOutput);
    else
        encodedData = WebPEncodeBGRA(data, (int)webPImageWidth, (int)webPImageHeight, (int)webPBytesPerRow, quality, &webPOutput);
    
    NSData *webPFinalData = [NSData dataWithBytes:webPOutput length:encodedData];
    
    data = nil;
    free(data);
    free(webPOutput);
    CGColorSpaceRelease(webPColorSpaceRef);
    CGContextRelease(context);
    CFRelease(webPImageDatRef);
    
    return webPFinalData;
}

- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha
{
    NSAssert(alpha >= 0 && alpha <= 1, @"imageByApplyingAlpha:alpha alpha has to be [0, 1]");
    
    if (alpha < 1) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        
        CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
        CGContextSetAlpha(ctx, alpha);
        
        CGContextDrawImage(ctx, area, self.CGImage);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    else {
        return self;
    }
}

@end