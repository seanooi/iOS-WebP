#iOS-WebP

Most apps nowadays enhance user experience with the use of images, and one of the issues I've noticed with that is the amount of time it takes to load an image. (_Not everyone has the luxury of a fast connection_)

Google's WebP image format offers better compression compared to PNG or JPEG, allowing apps to send/retrieve images with smaller file sizes, reducing request times and hopefully provide a better user experience.

![alt demo](http://i.imgur.com/tUCyYhD.png "Demo Screenshot")

#Getting Started

###The CocoaPods Way
```ruby
pod 'iOS-WebP', '0.4'
```

###The Manual Way
Include the 3 files inside the `iOS-WebP` folder into your project:
* `UIImage+WebP.h`
* `UIImage+WebP.m`
* `WebP.framework`

#Usage
Don't forget to `#import "UIImage+WebP.h"` or `#import <UIImage+WebP.h>` if you're using cocoapods.
There are 3 methods in `iOS-WebP`, converting images __to__ WebP format, converting images __from__ WebP format, and setting an image's transparency.
```objc
+ (void)imageToWebP:(UIImage *)image quality:(CGFloat)quality alpha:(CGFloat)alpha preset:(WebPPreset)preset
    completionBlock:(void (^)(NSData *result))completionBlock
       failureBlock:(void (^)(NSError *error))failureBlock;

+ (void)imageWithWebP:(NSString *)filePath
      completionBlock:(void (^)(UIImage *result))completionBlock
         failureBlock:(void (^)(NSError *error))failureBlock;

- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;
```

Encoding and decoding of images are done in the background thread and results returned in the completion block on the main thread so as not to lock the main thread, allowing the UI to be updated as needed.

#### Converting To WebP

```objc
// quality value is [0, 100]
// alpha value is [0, 1]
[UIImage imageToWebP:[UIImage imageNamed:@"demo.jpg"] quality:quality alpha:alpha preset:WEBP_PRESET_DEFAULT completionBlock:^(NSData *result) {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *webPPath = [paths[0] stringByAppendingPathComponent:@"image.webp"];
  if (![result writeToFile:webPPath atomically:YES]) {
    NSLog(@"Failed to save file");
  }
} failureBlock:^(NSError *error) {
  NSLog(@"%@", error.localizedDescription);
}];
```

#####`WebPPreset` possible values

* `WEBP_PRESET_DEFAULT` _(default preset)_
* `WEBP_PRESET_PICTURE` _(digital picture, like portrait, inner shot)_
* `WEBP_PRESET_PHOTO`   _(outdoor photograph, with natural lighting)_
* `WEBP_PRESET_DRAWING` _(hand or line drawing, with high-contrast details)_
* `WEBP_PRESET_ICON`    _(small-sized colorful images)_
* `WEBP_PRESET_TEXT`    _(text-like)_

##### Config block

If you need to fine tune the performance of the encoding algorithm you can specify overrides to the preset in a config block.

```objc
// quality value is [0, 100]
// alpha value is [0, 1]
[UIImage imageToWebP:[UIImage imageNamed:@"demo.jpg"] quality:quality alpha:alpha 
 preset:WEBP_PRESET_DEFAULT 
 config:^(WebPConfig *config) {
    config->sns_strength = 50.0f;
    config->filter_strength = 0.0f;
    config->method = 2;
    config->preprocessing = 0;
    config->filter_sharpness = 0;
    config->thread_level = 1;
 }
 completionBlock:^(NSData *result) {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *webPPath = [paths[0] stringByAppendingPathComponent:@"image.webp"];
  if (![result writeToFile:webPPath atomically:YES]) {
    NSLog(@"Failed to save file");
  }
} failureBlock:^(NSError *error) {
  NSLog(@"%@", error.localizedDescription);
}];
```

All possible config values can be found in encode.h in the WebPConfig stuct.

#### Converting From WebP

```objc
[UIImage imageWithWebP:@"/path/to/file" completionBlock:^(UIImage *result) {
  UIImageView *myImageView = [[UIImageView alloc] initWithImage:result];
}failureBlock:^(NSError *error) {
  NSLog(@"%@", error.localizedDescription);
}];
```

#### Setting Image Transparency

```objc
//alpha value is [0, 1]
UIImage *transparencyImage = [[UIImage imageNamed:image.jpg] imageByApplyingAlpha:0.5];
```

Credits
========
* Based off [WebP-iOS-example](https://github.com/carsonmcdonald/WebP-iOS-example "WebP-iOS-example") by Carson McDonald
* `imageByApplyingAlpha:alpha` function contributed by [shmidt](https://github.com/shmidt)
* `WebPConfig` block contributed by [weibel](https://github.com/weibel) and [escherba](https://github.com/escherba)
