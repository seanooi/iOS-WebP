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

// This gets called when the UIImage gets collected and frees the underlying image.
static void free_image_data(void *info, const void *data, size_t size)
{
    if(info != NULL)
        WebPFreeDecBuffer(&(((WebPDecoderConfig *)info)->output));
    else
        free((void *)data);
}

@implementation UIImage (WebP)

#pragma mark - Private methods
+ (NSData *)convertToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha
{
    NSLog(@"WebP Encoder Version: %@", [self version:WebPGetEncoderVersion()]);
    
    if (alpha < 1) {
        image = [self webPImage:image withAlpha:alpha];
    }
    
    // Construct CGCOntextRef from image to be encoded.
    // stride == BytesPerRow
    CGImageRef webPImageRef = image.CGImage;
    size_t webPBytesPerRow = CGImageGetBytesPerRow(webPImageRef);
    size_t webPBitsPerComponent = CGImageGetBitsPerComponent(webPImageRef);
    CGColorSpaceRef webPColorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo webPBitmapInfo = CGImageGetAlphaInfo(webPImageRef);
    
    size_t webPImageWidth = CGImageGetWidth(webPImageRef);
    size_t webPImageHeight = CGImageGetHeight(webPImageRef);
    
    CGDataProviderRef webPDataProviderRef = CGImageGetDataProvider(webPImageRef);
    CFDataRef webPImageDataRef = CGDataProviderCopyData(webPDataProviderRef);
    
    uint8_t *webPImageData = (uint8_t *)CFDataGetBytePtr(webPImageDataRef);
    uint8_t *webPOutput;
    
    CGContextRef context = CGBitmapContextCreate(webPImageData, webPImageWidth, webPImageHeight, webPBitsPerComponent, webPBytesPerRow, webPColorSpaceRef, (CGBitmapInfo)webPBitmapInfo);
    void *data = CGBitmapContextGetData(context);
    
    // Encode the image into `webPOutput` and pass it into `NSData` to be returned to caller
    size_t encodedData = WebPEncodeRGBA(data, (int)webPImageWidth, (int)webPImageHeight, (int)webPBytesPerRow, quality, &webPOutput);
    NSData *webPFinalData = [NSData dataWithBytes:webPOutput length:encodedData];
    
    // Free resources to avoid memory leaks
    data = nil;
    free(data);
    free(webPOutput);
    CGColorSpaceRelease(webPColorSpaceRef);
    CGContextRelease(context);
    CFRelease(webPImageDataRef);
    
    return webPFinalData;
}

+ (UIImage *)convertFromWebP:(NSString *)filePath
{
    NSLog(@"WebP Decoder Version: %@", [self version:WebPGetDecoderVersion()]);
    
    // If passed `filepath` is invalid, return nil to caller and log error in console
    NSError *error = nil;;
    NSData *imgData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if(error != nil) {
        NSLog(@"imageFromWebP: error: %@", error.localizedDescription);
        return nil;
    }
    
    // `WebPGetInfo` weill return image width and height
    int width = 0, height = 0;
    WebPGetInfo([imgData bytes], [imgData length], &width, &height);
    
    // Decode image into RGBA value array
    uint8_t *data = WebPDecodeRGBA([imgData bytes], [imgData length], &width, &height);
    
    // Construct UIImage from the decoded RGBA value array
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, width * height * 4, free_image_data);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault |kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    // Free resources to avoid memory leaks
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    return result;
}

#pragma mark - Synchronous methods
+ (UIImage *)imageFromWebP:(NSString *)filePath
{
    NSAssert(filePath != nil, @"imageFromWebP:filePath filePath cannot be nil");
    
    return [self convertFromWebP:filePath];
}

+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality
{
    NSAssert(image != nil, @"imageToWebP:quality image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality quality has to be [0, 100]");
    
    return [self convertToWebP:image quality:quality alpha:1];
}

#pragma mark - Asynchronous methods
+ (void)imageFromWebP:(NSString *)filePath completionBlock:(void (^)(UIImage *result))completionBlock failureBlock:(void (^)(NSString *))failureBlock
{
    NSAssert(filePath != nil, @"imageFromWebP:filePath:completionBlock:failureBlock filePath cannot be nil");
    NSAssert(completionBlock != nil, @"imageFromWebP:filePath:completionBlock:failureBlock completionBlock block cannot be nil");
    NSAssert(failureBlock != nil, @"imageFromWebP:filePath:completionBlock:failureBlock failureBlock block cannot be nil");
    
    // Create dispatch_queue_t for decoding WebP concurrently
    dispatch_queue_t fromWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.fromwebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(fromWebPQueue, ^{
        
        UIImage *webPImage = [self convertFromWebP:filePath];
        
        // Return results to caller on main thread in completion block is `webPImage` != nil
        // Else return in failure block
        if(webPImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPImage);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(@"Conversion error");
            });
        }
    });
}

+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha completionBlock:(void (^)(NSData *result))completionBlock failureBlock:(void (^)(NSString *error))failureBlock
{
    NSAssert(image != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock image cannot be nil");
    NSAssert(quality >= 0 && quality <= 100, @"imageToWebP:quality:alpha:completionBlock:failureBlock quality has to be [0, 100]");
    NSAssert(alpha >= 0 && alpha <= 1, @"imageToWebP:quality:alpha:completionBlock:failureBlock alpha has to be [0, 1]");
    NSAssert(completionBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock completionBlock cannot be nil");
    NSAssert(completionBlock != nil, @"imageToWebP:quality:alpha:completionBlock:failureBlock failureBlock block cannot be nil");
    
    // Create dispatch_queue_t for encoding WebP concurrently
    dispatch_queue_t toWebPQueue = dispatch_queue_create("com.seanooi.ioswebp.towebp", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(toWebPQueue, ^{
        
        NSData *webPFinalData = [self convertToWebP:image quality:quality alpha:alpha];
        
        // Return results to caller on main thread in completion block is `webPFinalData` != nil
        // Else return in failure block
        if(webPFinalData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(webPFinalData);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(@"Conversion error");
            });
        }
    });
}

#pragma mark - Utilities
- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha
{
    NSAssert(alpha >= 0 && alpha <= 1, @"imageByApplyingAlpha:alpha alpha has to be [0, 1]");
    
    if (alpha < 1) {
        
       UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
       
       CGContextRef ctx = UIGraphicsGetCurrentContext();
       CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
       
       CGContextScaleCTM(ctx, 1, -1);
       CGContextTranslateCTM(ctx, 0, -area.size.height);
       
       CGContextSetAlpha(ctx, alpha);
       CGContextSetBlendMode(ctx, kCGBlendModeXOR);
       CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
       
       CGContextDrawImage(ctx, area, self.CGImage);
       
       UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
       
       UIGraphicsEndImageContext();
        
        return newImage;
         
    }
    else {
        return self;
    }
}

+ (UIImage *)webPImage:(UIImage *)image withAlpha:(CGFloat)alpha
{
    // CGImageAlphaInfo of images with alpha are kCGImageAlphaPremultipliedFirst
    // Convert to kCGImageAlphaPremultipliedLast to avoid gray-ish background when encoding alpha images to WebP format
    
    CGImageRef imageRef = image.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UInt8* pixelBuffer = malloc(height * width * 4);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(pixelBuffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    CGDataProviderRef dataProviderRef = CGImageGetDataProvider(imageRef);
    CFDataRef dataRef = CGDataProviderCopyData(dataProviderRef);
    
    GLubyte *pixels = (GLubyte *)CFDataGetBytePtr(dataRef);
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            NSInteger byteIndex = ((width * 4) * y) + (x * 4);
            pixelBuffer[byteIndex + 3] = pixels[byteIndex +3 ]*alpha;
        }
    }
    
    CGContextRef ctx = CGBitmapContextCreate(pixelBuffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef newImgRef = CGBitmapContextCreateImage(ctx);
    
    free(pixelBuffer);
    CFRelease(dataRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    
    UIImage *newImage = [UIImage imageWithCGImage:newImgRef];
    CGImageRelease(newImgRef);
    
    return newImage;
}

+ (NSString *)version:(NSInteger)version
{
    // Convert version number to hexadecimal and parse it accordingly
    // E.g: v2.5.7 is 0x020507
    
    NSString *hex = [NSString stringWithFormat:@"%06lx", (long)version];
    NSMutableArray *array = [NSMutableArray array];
    for (int x = 0; x < [hex length]; x += 2) {
        [array addObject:@([[hex substringWithRange:NSMakeRange(x, 2)] integerValue])];
    }
    
    return [array componentsJoinedByString:@"."];
}

@end
