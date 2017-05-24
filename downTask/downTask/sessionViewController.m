//
//  sessionViewController.m
//  downTask
//
//  Created by 吴冕 on 2017/5/22.
//  Copyright © 2017年 wumian. All rights reserved.
//
#define CACHE  [NSHomeDirectory() stringByAppendingString:@"/Library/downTask"]
#define DOWNNAME @"sogou_mac_32c_V3.2.0.1437101586"
#define LENGHT [[NSHomeDirectory() stringByAppendingString:@"/Library/downTask"] stringByAppendingPathComponent:@"lenght"]

#import "sessionViewController.h"
#import <CommonCrypto/CommonDigest.h>

@interface sessionViewController ()<NSURLSessionDataDelegate>

@property (nonatomic,strong)UIProgressView *progressView;

@property (nonatomic,strong)UILabel *textLabel;

@property (nonatomic,strong)UIButton *btn;

@property (nonatomic,strong)UIButton *closeBtn;

@property (nonatomic,strong)NSURLSessionDataTask *downloadTask;

@property (nonatomic,strong)NSURLSession *session;

@property (nonatomic,strong)NSFileHandle *filehandle;

@property (nonatomic,assign)double totalLenght;

@property (nonatomic,assign)double currentLenght;

@end

@implementation sessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 界面
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 100, 300, 5)];
    progressView.tintColor = [UIColor redColor];
    progressView.trackTintColor = [UIColor lightGrayColor];
    self.progressView = progressView;
    [self.view addSubview:progressView];
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(330, 90, 20, 20)];
    [closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
    self.closeBtn = closeBtn;
    self.closeBtn.enabled = NO;
    [self.view addSubview:closeBtn];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 130, 100, 20)];
    textLabel.font = [UIFont fontWithName:@"American Typewriter" size:24];
    self.textLabel = textLabel;
    [self.view addSubview:textLabel];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(150, 200, 50, 50)];
    [btn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    self.btn = btn;
    [self.view addSubview:btn];
}

// 创建任务
- (void)createDownTask{
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];// 默认配置
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.session = session;

    NSURL *downURL = [NSURL URLWithString:@"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downURL];
    //设置请求头
    NSString *cache =  CACHE;
    NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil][NSFileSize] intValue]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *downloadTask = [self.session dataTaskWithRequest:request];
    if(self.downloadTask){
        self.downloadTask = nil;
    }
    self.downloadTask = downloadTask;
    if ([[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil][NSFileSize] intValue] != 0) {
        self.closeBtn.enabled = YES;
    }
}

// 开始/暂停任务
- (void)btnClick:(UIButton *)btn{
    btn.selected = !btn.isSelected;
    if (btn.isSelected) {
        self.closeBtn.enabled = YES;
        [self createDownTask];
        [self.downloadTask resume];
    }else {
        [self.downloadTask suspend];
    }
}

// 默认下session会一直下载，需要手动关闭
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.downloadTask suspend];
}

// 手动关闭下载任务，清除内存
- (void)closeClick:(UIButton *)sender{
    [self.session invalidateAndCancel];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"确定取消任务？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.progressView.progress = 0.00;
        self.textLabel.text = @"0.00%";
        
        NSString *cache =  CACHE;
        NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
        NSFileManager *mgr = [NSFileManager defaultManager];
        [mgr removeItemAtPath:fileName error:nil];
        self.closeBtn.enabled = NO;
        self.btn.selected = NO;
    }];
    
    UIAlertAction *alertB = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alertC dismissViewControllerAnimated:YES completion:nil];
        _btn.selected = NO;
        [self btnClick:self.btn];
    }];
    [alertC addAction:alertA];
    [alertC addAction:alertB];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

/**
 *  1.接收到服务器的响应就会调用
 *
 *  @param response   响应
 */
#pragma mark
#pragma make - 判断是否已经下载过
- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *cache = CACHE;
    NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
    self.currentLenght = [[mgr attributesOfItemAtPath:fileName error:nil][NSFileSize] doubleValue];
    // 下载文件的总长度
    self.totalLenght = (double)response.expectedContentLength + self.currentLenght;
    if (![mgr fileExistsAtPath:fileName]) {
        [mgr createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
        [mgr createFileAtPath:fileName contents:nil attributes:nil];
    }else if([[mgr attributesOfItemAtPath:fileName error:nil][NSFileSize] doubleValue] == response.expectedContentLength + self.currentLenght){
        self.progressView.progress = 1.0;
        self.textLabel.text = @"1.00%";
        completionHandler(NSURLSessionResponseCancel);
        [self createAlterView];
        return;
    }
    // 文件的句柄
    self.filehandle = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    self.progressView.progress = self.currentLenght / self.totalLenght;
    self.textLabel.text = [NSString stringWithFormat:@"%.2f%%",self.progressView.progress];
    completionHandler(NSURLSessionResponseAllow);
}

/**
 *  2.当接收到服务器返回的实体数据时调用（具体内容，这个方法可能会被调用多次）
 *
 *  @param data       这次返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    // 句柄移动到文件的末尾
    [self.filehandle seekToEndOfFile];
    // 写入文件
    [self.filehandle writeData:data];
    // 累计长度
    self.currentLenght += data.length;
    
    // 显示进度
    self.progressView.progress = self.currentLenght / self.totalLenght;
    self.textLabel.text = [NSString stringWithFormat:@"%.2f%%",self.currentLenght / self.totalLenght];
}

/**
 *  3.加载完毕后调用（服务器的数据已经完全返回后）
 */

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    [self.filehandle closeFile];
    self.filehandle = nil;
    [self createAlterView];
}

- (void)viewWillAppear:(BOOL)animated{
    
}
- (void)viewDidAppear:(BOOL)animated{
    
}
// 提示出下载文件的大小和存储的位置
- (void)createAlterView{
    self.btn.selected = NO;
    self.closeBtn.enabled = NO;
    NSString *cache = CACHE;
    NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSDictionary<NSFileAttributeKey, id> *dict = [mgr attributesOfItemAtPath:fileName error:nil];
    NSInteger fileSize = [dict[NSFileSize] doubleValue] / 1024.0 / 1024.0;
    NSString *fileSizeString = [NSString stringWithFormat:@"%.2ld",(long)fileSize];
    if ([dict[NSFileSize] doubleValue] == self.totalLenght) {
        NSString *message = [NSString stringWithFormat:@"文件大小:%@M 文件地址：%@",fileSizeString,fileName];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"下载完成" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sureBtn = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        // 下载文件的属性
        [alertController addAction:sureBtn];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}



@end

