//
//  CDVBCSViewController.h
//  mbyte
//  CDBBarcodeScanViewController
//
//  Created by xyl 2015-12-11 21:05:35.
//  Copyright (c) 2015年 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "CDVXYLBarcodeScanner.h"

//@class  CDVXYLBarcodeScanner;



@interface CDVBCSViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate,CDVBarcodeScannerOrientationDelegate>
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
    //NSString*       callback;
    
    
}

@property (nonatomic, strong) CDVXYLBarcodeScanner *plugin;
@property (nonatomic, strong) NSString * callback;


@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (nonatomic, retain) UIImageView * line;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

@property (assign) id orientationDelegate;


-(BOOL)startReading;
-(void)stopReading;
-(void)loadBeepSound;

//@property (nonatomic,strong)


@end
