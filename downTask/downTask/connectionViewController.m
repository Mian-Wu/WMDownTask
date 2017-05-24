//
//  connectionViewController.m
//  downTask
//
//  Created by 吴冕 on 2017/5/24.
//  Copyright © 2017年 wumian. All rights reserved.
//
#define CACHE  [NSHomeDirectory() stringByAppendingString:@"/Library/downTask"]
#define DOWNNAME @"sogou_mac_32c_V3.2.0.1437101587"
#define LENGHT [[NSHomeDirectory() stringByAppendingString:@"/Library/downTask"] stringByAppendingPathComponent:@"lenght"]

#import "connectionViewController.h"

@interface connectionViewController ()<NSURLConnectionDelegate>

@property (nonatomic,strong)UIProgressView *progressView;

@property (nonatomic,strong)UILabel *textLabel;

@property (nonatomic,strong)UIButton *closeBtn;

@property (nonatomic,strong)UIButton *btn;

@property (nonatomic,strong)NSURLConnection *connect;

@property (nonatomic,strong)NSOutputStream *outPut;

@property (nonatomic,assign)double totalLenght;

@property (nonatomic,assign)double currentLenght;

@end

@implementation connectionViewController

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
    NSURL *downURL = [NSURL URLWithString:@"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downURL];
    //设置请求头
    NSString *cache =  CACHE;
    NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil][NSFileSize] intValue]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    //开始下载,通过遵守代理协议，回调下载过程
    self.connect = [NSURLConnection connectionWithRequest:request delegate:self];
    
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
    }else {
        [self.connect cancel];
    }
    
}

// 默认下session会一直下载，需要手动关闭
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.connect cancel];
}

// 手动关闭下载任务，清除内存
- (void)closeClick:(UIButton *)sender{
    [self.connect cancel];
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
        _btn.selected= NO;
        [self btnClick:self.btn];
    }];
    [alertC addAction:alertA];
    [alertC addAction:alertB];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

#pragma mark
#pragma make - 代理下载
/**
 *  1.接收到服务器的响应就会调用
 *
 *  @param response   响应
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(nonnull NSURLResponse *)response{
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *cache =  CACHE;
    NSString *fileName = [cache stringByAppendingPathComponent:DOWNNAME];
    self.currentLenght = [[mgr attributesOfItemAtPath:fileName error:nil][NSFileSize] doubleValue];
    if (![mgr fileExistsAtPath:fileName]) {
        [mgr createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
        [mgr createFileAtPath:fileName contents:nil attributes:nil];
    }else if([[mgr attributesOfItemAtPath:fileName error:nil][NSFileSize] doubleValue] == response.expectedContentLength + self.currentLenght){
        self.progressView.progress = 1.0;
        self.textLabel.text = @"1.00%";
        [self createAlterView];
        return;
    }
    // 文件的句柄
    self.outPut = [NSOutputStream outputStreamToFileAtPath:fileName append:YES];
    [self.outPut open];
    // 下载文件的总长度
    self.totalLenght = (double)response.expectedContentLength + self.currentLenght;
    self.progressView.progress = self.currentLenght / self.totalLenght;
    self.textLabel.text = [NSString stringWithFormat:@"%.2f%%",self.progressView.progress];
}

//接收到数据
- (void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data{
    self.currentLenght += data.length;
    self.progressView.progress = self.currentLenght / self.totalLenght;
    self.textLabel.text = [NSString stringWithFormat:@"%.2f%%",self.progressView.progress];
    
    [self.outPut write:data.bytes maxLength:data.length];
}

//下载完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //关闭文件
    [self.outPut close];
    self.outPut = nil;
    [self createAlterView];
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
