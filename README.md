#iOS-WebP

Most apps nowadays enhance user experience with the use of images, and one of the issues I've noticed with that is the amount of time it takes to load and image. (_Not everyone has the luxury of a fast connection_)

Google's WebP image format offers better compression compared to PNG or JPEG, allowing apps to send/retrieve images with smaller file sizes, reducing request times and hopefully providing a better user experience.

![alt demo](http://i.imgur.com/V4fBG1h.png "Demo Screenshot")

#Getting Started

###The CocoaPods Way
```ruby
pod 'iOS-WebP', '0.1'
```

###The Manual Way
Include the 3 files inside the `iOS-WebP` folder into your project:
* `UIImage+WebP.h`
* `UIImage+WebP.m`
* `WebP.framework`

#Usage
Don't forget to `#import "UIImage+WebP.h"` or `#import <UIImage+WebP.h>` if you're using cocoapods.
There are 2 methods in `iOS-WebP`, converting images __to__ WebP format and converting images __from__ WebP format.
```objective-c
+ (UIImage *)imageFromWebP:(NSString *)filePath;
+ (NSData *)imageToWebP:(UIImage *)image quality:(CGFloat)quality;
```

Using the methods are pretty easy:

```objective-c
//Converting To WebP
NSData *webpData = [UIImage imageToWebP:[UIImage imageNamed:@"image.jpg"] quality:75];

//Converting From WebP
UIImage *webPImage = [UIImage imageFromWebP:@"/path/to/file"]
```

Credit
========
Based off [WebP-iOS-example](https://github.com/carsonmcdonald/WebP-iOS-example "WebP-iOS-example") by Carson McDonald
