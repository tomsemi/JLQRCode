//
//  JLQRCaptureViewController.m
//  JLQRCode
//
//  Created by Jason Li on 8/17/16.
//  Copyright © 2016 zrxd. All rights reserved.
//

#import "JLQRCaptureViewController.h"
#import "JLQRCodeScanViewController.h"

#import "NSString+LocaliziedString.h"

NSArray * JLFeaturesQRCode(UIImage *image) {
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode
                                                  context:nil
                                                  options:detectorOptions];
    int exifOrientation;
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    
    return [faceDetector featuresInImage:[CIImage imageWithCGImage:image.CGImage]
                                 options:@{CIDetectorImageOrientation:[NSNumber numberWithInt:exifOrientation]}];
}

@interface JLQRCaptureViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, copy) JLQRCaptureCompletion blcokCompletion;

@property (nonatomic, strong) JLQRCodeScanViewController *scanVC;
@property (nonatomic, strong) UILabel *labNote;

@property (nonatomic, strong) UIImagePickerController *pickerController;

@end

@implementation JLQRCaptureViewController

+ (instancetype)QRCapturePresentController:(UIViewController *)viewController
                                 withTitle:(NSString *)title
                         captureCompletion:(void (^)(NSString *, BOOL))completion {
    JLQRCaptureViewController *capture = [[JLQRCaptureViewController alloc] init];
    capture.title = title;
    capture.blcokCompletion = completion;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:capture];
    [nav.navigationBar setBarStyle:UIBarStyleBlack];
    
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [nav.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor] ,NSForegroundColorAttributeName, nil]];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:[NSString jl_LocaliziedStringForKey:@"Cancel"]
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:capture
                                                                  action:@selector(actionToOperCancel)];
    [capture.navigationItem setLeftBarButtonItem:cancelItem];
    
    UIBarButtonItem *itemAlbum = [[UIBarButtonItem alloc] initWithTitle:[NSString jl_LocaliziedStringForKey:@"Album"]
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:capture
                                                                 action:@selector(actionToOperAlbum)];
    [capture.navigationItem setRightBarButtonItem:itemAlbum];
    
    capture.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [viewController presentViewController:nav animated:YES completion:nil];
    
    return capture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self addChildViewController:self.scanVC];
    [self.view addSubview:self.scanVC.view];
    [self.scanVC didMoveToParentViewController:self];
    
    [self.view addSubview:self.labNote];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.labNote setFrame:self.view.bounds];
    
}

#pragma mark - Getter And Setter
- (JLQRCodeScanViewController *)scanVC {
    if (_scanVC) return _scanVC;
    _scanVC = [[JLQRCodeScanViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    _scanVC.blockCompletion = ^(NSString *codeString, BOOL isQRCode) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (weakSelf.blcokCompletion) weakSelf.blcokCompletion(codeString,isQRCode);
        }];
    };
    
    return _scanVC;
}

- (UIImagePickerController *)pickerController {
    if (_pickerController) return _pickerController;
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    _pickerController.delegate = self;
    
    return _pickerController;
}

- (UILabel *)labNote {
    if (_labNote) return _labNote;
    _labNote = [[UILabel alloc] init];
    [_labNote setHidden:YES];
    _labNote.backgroundColor = [UIColor colorWithWhite:.1f alpha:.9f];
    _labNote.textAlignment = NSTextAlignmentCenter;
    _labNote.numberOfLines = 0;
    _labNote.textColor = [UIColor whiteColor];
    
    [_labNote setUserInteractionEnabled:YES];
    [_labNote addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionToDealCaptureAgain)]];
    
    _labNote.text = [NSString stringWithFormat:@"%@\n%@",[NSString jl_LocaliziedStringForKey:@"No Found QRCode"],[NSString jl_LocaliziedStringForKey:@"Tap And Continue"]];
    _labNote.font = [UIFont systemFontOfSize:16.f];
    
    NSMutableAttributedString *string = nil;
    if (_labNote.attributedText) {
        string = [[NSMutableAttributedString alloc] initWithAttributedString:_labNote.attributedText];
    } else {
        string = [[NSMutableAttributedString alloc] initWithString:_labNote.text];
        [string addAttribute:NSFontAttributeName value:_labNote.font range:NSMakeRange(0, _labNote.text.length)];
        [string addAttribute:NSForegroundColorAttributeName value:_labNote.textColor range:NSMakeRange(0, _labNote.text.length)];
        [string addAttribute:NSBackgroundColorAttributeName value:_labNote.backgroundColor range:NSMakeRange(0, _labNote.text.length)];
    }
    
    NSRange range = [_labNote.text rangeOfString:[NSString jl_LocaliziedStringForKey:@"Tap And Continue"]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:range];
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f] range:range];
    
    _labNote.attributedText = string;
    return _labNote;
}

#pragma mark - Action
- (void)actionToOperCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionToOperAlbum {
    [self.scanVC stopRunning];
    [self.labNote setHidden:YES];
    if ([self isPhotoLibraryAvailable]) {
        [self presentViewController:self.pickerController animated:YES completion:nil];
    }
}

- (void)actionToDealCaptureAgain {
    [self.scanVC startRunning];
    [self.labNote setHidden:YES];
}

#pragma mark camera utility
- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self.pickerController dismissViewControllerAnimated:YES completion:nil];
    NSArray *features = JLFeaturesQRCode([info objectForKey:UIImagePickerControllerOriginalImage]);
    
    NSString *content = @"";
    if (features.count) {
        for (CIFeature *feature in features) {
            if ([feature isKindOfClass:[CIQRCodeFeature class]]) {
                content = ((CIQRCodeFeature *)feature).messageString;
                break;
            }
        }
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            if (weakSelf.blcokCompletion) weakSelf.blcokCompletion(content,YES);
        }];
    } else {
        [self.labNote setHidden:NO];
    }
}

@end
