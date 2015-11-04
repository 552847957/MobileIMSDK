//  ----------------------------------------------------------------------
//  Copyright (C) 2015 Jack Jiang The MobileIMSDK Project.
//  All rights reserved.
//  Project URL:  https://github.com/JackJiang2011/MobileIMSDK
//
//  openmob.net PROPRIETARY/CONFIDENTIAL. Use is subject to license terms.
//
//  You can contact author with jack.jiang@openmob.net or jb2011@163.com.
//  ----------------------------------------------------------------------
//
//  ViewController.m
//  RainbowCore4i
//
//  Created by JackJiang on 14/10/21.
//  Copyright (c) 2014年 cngeeker.com. All rights reserved.
//

#import "ViewController.h"
#import "ConfigEntity.h"
#import "Toast+UIView.h"
#import "ToolKits.h"
#import "ClientCoreSDK.h"
#import "LocalUDPDataSender.h"
#import "ErrorCode.h"
#import "Protocal.h"
#import "AutoReLoginDaemon.h"
#import "KeepAliveDaemon.h"
#import "QoS4ReciveDaemon.h"
#import "QoS4SendDaemon.h"
#import "ChatBaseEventImpl.h"
#import "ChatInfoTableViewCellDTO.h"
#import "ChatInfoTableViewCell.h"

static const int TABLE_CELL_COLOR_BLACK = 0;
static const int TABLE_CELL_COLOR_BLUE = 1;
static const int TABLE_CELL_COLOR_BRIGHT_RED = 2;
static const int TABLE_CELL_COLOR_RED = 3;
static const int TABLE_CELL_COLOR_GREEN = 4;



@interface ViewController ()
{
    // cht info time
    NSDateFormatter *hhmmssFormat;
}

// 用于主界面表格的数据显示
@property (nonatomic, retain) NSMutableArray* chatInfoList;

@end

@implementation ViewController

@synthesize myId;
@synthesize messageField;

//@synthesize iviewLocalNetwork;
//@synthesize iviewIsLogin;
@synthesize iviewOnline;
@synthesize iviewAutoRelogin;
@synthesize iviewKeepAlive;
@synthesize iviewQoSSend;
@synthesize iviewQoSReceive;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        //
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // chat info time
    hhmmssFormat = [[NSDateFormatter alloc] init];
    [hhmmssFormat setDateFormat:@"HH:mm:ss"];
    
    // 表格基本设置
    self.chatInfoList = [[NSMutableArray alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // just for debug START
    [self initObserversForDEBUG];
    // just for debug END
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    self.addrField.text = [ConfigEntity getServerIp];
//    self.portField.text = [NSString stringWithFormat:@"%d", [ConfigEntity getServerPort]];
}

- (IBAction)clickBgToHideKeyboard:(id)sender
{
    NSLog(@"点击了背景！");
    
    // 以下代码实现隐藏键盘(iOS 6及更老的系统很有用)
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (void) setMyid:(int)myid
{
    self.myId.text = (myid == -1 ? @"未登陆" : [NSString stringWithFormat:@"%d", myid]);
}

- (void) showToastInfo:(NSString *)title withContent:(NSString *)content
{
    // Make toast with an image & title
    [self.view makeToast:content
                duration:3.0
                position:@"top"
                   title:title
                   image:[UIImage imageNamed:@"info.png"]];
}

- (void) showIMInfo_black:(NSString*)txt
{
    [self showIMInfo:txt withColorType:TABLE_CELL_COLOR_BLACK];
}
- (void) showIMInfo_blue:(NSString*)txt
{
    [self showIMInfo:txt withColorType:TABLE_CELL_COLOR_BLUE];
}
- (void) showIMInfo_brightred:(NSString*)txt
{
    [self showIMInfo:txt withColorType:TABLE_CELL_COLOR_BRIGHT_RED];
}
- (void) showIMInfo_red:(NSString*)txt
{
    [self showIMInfo:txt withColorType:TABLE_CELL_COLOR_RED];
}
- (void) showIMInfo_green:(NSString*)txt
{
    [self showIMInfo:txt withColorType:TABLE_CELL_COLOR_GREEN];
}
- (void) showIMInfo:(NSString*)txt withColorType:(int)colorType
{
    ChatInfoTableViewCellDTO *dto = [[ChatInfoTableViewCellDTO alloc] init];
    dto.colorType = colorType;
    dto.content = [NSString stringWithFormat:@"[%@] %@", [hhmmssFormat stringFromDate:[[NSDate alloc] init]], txt];
    [self.chatInfoList addObject:dto];
    [self.tableView reloadData];
    
    // 自动显示最后一行
    NSInteger s = [self.tableView numberOfSections];
    if (s<1) return;
    NSInteger r = [self.tableView numberOfRowsInSection:s-1];
    if (r<1) return;
    NSIndexPath *ip = [NSIndexPath indexPathForRow:r-1 inSection:s-1];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (IBAction)signIn:(id)sender
{
    // 设置服务器地址和端口号[dirtyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlin
    NSString *serverIP = [self.addrField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *serverPort = self.portField.text;
//	int serverPort = [self.portField.text intValue];;
    if(!([serverIP length] <= 0)
        && !([serverPort length] <= 0))
    {
        [ConfigEntity setServerIp:serverIP];
        [ConfigEntity setServerPort:[serverPort intValue]];
    }
    else
    {
        [self showToastInfo:@"提示" withContent:@"请确保服务端地址和端口号都不为空！"];
        [self showIMInfo_red: @"请确保服务端地址和端口号都不为空！"];
        return;
    }
    
    // 登陆名和密码
    NSString *loginNameStr = self.loginName.text;
    if ([loginNameStr length] == 0)
    {
        [self showToastInfo:@"提示" withContent:@"请输入登陆名！"];
        return;
    }
    NSString *loginPswStr = self.loginPsw.text;
    if ([loginPswStr length] == 0)
    {
        [self showToastInfo:@"提示" withContent:@"请输入登密码！"];
        return;
    }
    
    // just for debug START
    if([ClientCoreSDK sharedInstance].chatBaseEvent != nil)
    {
        ((ChatBaseEventImpl *)([ClientCoreSDK sharedInstance].chatBaseEvent)).debugObserver = [self createObserverCompletionForDEBUG:iviewOnline];
    }
    // just for debug END
    
    // 发送登陆数据包(提交登陆名和密码)
    int code = [[LocalUDPDataSender sharedInstance] sendLogin:loginNameStr withPassword:loginPswStr];
    if(code == COMMON_CODE_OK)
    {
        [self showToastInfo:@"提示" withContent:@"登陆请求已发出。。。"];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"登陆请求发送失败，错误码：%d", code];
        [self showToastInfo:@"错误" withContent:msg];
    }
}

- (IBAction)signOut:(id)sender
{
    // 发出退出登陆请求包
    int code = [[LocalUDPDataSender sharedInstance] sendLoginout];
    if(code == COMMON_CODE_OK)
    {
        [self showToastInfo:@"提示" withContent:@"注销登陆请求已完成。。。"];
        [self setMyid:-1];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"注销登陆请求发送失败，错误码：%d", code];
        [self showToastInfo:@"错误" withContent:msg];
    }
    
    // just for debug START
     ObserverCompletion oc = ((ChatBaseEventImpl *)([ClientCoreSDK sharedInstance].chatBaseEvent)).debugObserver = [self createObserverCompletionForDEBUG:iviewOnline];
    if(oc != nil)
        oc(nil,0);
    // just for debug END
}

- (IBAction)send:(id)sender
{
    NSString *dicStr = self.messageField.text;
    if ([dicStr length] == 0)
    {
        [self showToastInfo:@"提示" withContent:@"请输入消息内容！"];
        return;
    }
    
    NSString *friendIdStr = self.friendId.text;
    if ([friendIdStr length] == 0)
    {
        [self showToastInfo:@"提示" withContent:@"请输入对方id！"];
        return;
    }
    
    //
    [self showIMInfo_black:[NSString stringWithFormat:@"我对%@说：%@", friendIdStr, dicStr]];
    
    //** [1] 发送不需要QoS支持的消息
//  int code = [[LocalUDPDataSender sharedInstance] sendCommonDataWithStr:dicStr toUserId:[friendIdStr intValue]];
    
    //** [2] 发送需要QoS支持的消息
//    NSString *fingerPring = [Protocal genFingerPrint];
//    int code = [[LocalUDPDataSender sharedInstance] sendCommonDataWithStr:dicStr toUserId:[friendIdStr intValue] qos:YES fp:fingerPring];
    int code = [[LocalUDPDataSender sharedInstance] sendCommonDataWithStr:dicStr toUserId:[friendIdStr intValue] qos:YES fp:nil];
    
    if(code == COMMON_CODE_OK)
    {
//        [self showToastInfo:@"提示" withContent:@"您的消息已发出。。。"];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"您的消息发送失败，错误码：%d", code];
        [self showToastInfo:@"错误" withContent:msg];
    }
}

- (IBAction)TextField_DidEndOnExit:(id)sender
{
    // 隐藏键盘
    [sender resignFirstResponder];
}

//===============================================================================  just for debug START
#pragma mark -
#pragma mark - 以下代码用于DEBUG时显示各种状态

- (void) showDebugStatusImage:(int)status forImageView:(UIImageView *)iv
{
    if(iv.hidden)
        iv.hidden = NO;
    if(status == 1)
    {
        // 确保先stop ，否则正在动画中时此时设置图片则只会停在动画的最后一帧
        if([iv isAnimating])
            [iv stopAnimating];
        [iv setImage:[UIImage imageNamed:@"green.png"]];
    }
    else if(status == 2)
    {
        [iv setImage:[UIImage imageNamed:@"green.png"]];
        if([iv isAnimating])
            [iv stopAnimating];
        [iv startAnimating];
    }
    else
    {
        // 确保先stop ，否则正在动画中时此时设置图片则只会停在动画的最后一帧
        if([iv isAnimating])
            [iv stopAnimating];
        [iv setImage:[UIImage imageNamed:@"gray.png"]];
    }
}

- (void) setupAnimationForStatusImage:(UIImageView *)iv
{
    iv.animationImages = [NSArray arrayWithObjects:
                                          [UIImage imageNamed:@"green_light.png"],
                                          [UIImage imageNamed:@"green.png"],
                                          nil];
    iv.animationDuration = 0.5;
    iv.animationRepeatCount = 1;
}

- (ObserverCompletion) createObserverCompletionForDEBUG:(UIImageView *)iv
{
    ObserverCompletion clp = ^(id observerble ,id data) {
        int status = [(NSNumber *)data intValue];
        [self showDebugStatusImage:status forImageView:iv];

    };
    
    return clp;
}

- (void) initObserversForDEBUG
{
    [self setupAnimationForStatusImage:iviewAutoRelogin];
    [self setupAnimationForStatusImage:iviewKeepAlive];
    [self setupAnimationForStatusImage:iviewQoSSend];
    [self setupAnimationForStatusImage:iviewQoSReceive];
    
//    [[ClientCoreSDK sharedInstance] setDebugObserver:[self createObserverCompletion:iviewLocalNetwork]];
    [[AutoReLoginDaemon sharedInstance] setDebugObserver:[self createObserverCompletionForDEBUG:iviewAutoRelogin]];
    [[KeepAliveDaemon sharedInstance] setDebugObserver:[self createObserverCompletionForDEBUG:iviewKeepAlive]];
    [[ProtocalQoS4SendProvider sharedInstance] setDebugObserver:[self createObserverCompletionForDEBUG:iviewQoSSend]];
    [[ProtocalQoS4ReciveProvider sharedInstance] setDebugObserver:[self createObserverCompletionForDEBUG:iviewQoSReceive]];
}
//=============================================================================== just for debug END

//=============================================================================== 有关主界面表格的托管实现方法 START
#pragma mark -
#pragma mark - Table view delegate

// 根据显示内容计算行高
- (CGSize)_calculateCellSize:(NSIndexPath *)indexPath
{
    // 列寬
    CGFloat contentWidth = self.tableView.frame.size.width;
    
    if(self.chatInfoList == nil)
        return CGSizeMake(contentWidth, 16);
    
    ChatInfoTableViewCellDTO * item = [self.chatInfoList objectAtIndex:indexPath.section];
    
    // 用何種字體進行顯示
    UIFont *font = [UIFont systemFontOfSize:14];// Bug FIX: 此字号设为12时，在iPhone5C(iOS7.0(11A466))真机上会出现字体显示不全的bug（下偏），但其它真机包括模拟器上却不会，难道是iOS7.0的bug？-- By Jack Jiang 2015-09-16
    // 該行要顯示的內容
    NSString *content = item.content;
    // 計算出顯示完內容需要的最小尺寸
    CGSize size = [content sizeWithFont:font constrainedToSize:CGSizeMake(contentWidth, 1000) lineBreakMode:NSLineBreakByCharWrapping];
    
    // NSLog(@"-------计算出的高度=%f", size.height);
    
    return size;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.chatInfoList == nil?0:[self.chatInfoList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _calculateCellSize:indexPath].height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.chatInfoList == nil)
        return nil;
    
    ChatInfoTableViewCellDTO * item = [self.chatInfoList objectAtIndex:indexPath.section];
    
    // 表格单元可重用ui
    static NSString *idenfity=@"Cell";
    ChatInfoTableViewCell * cell=[tableView dequeueReusableCellWithIdentifier:idenfity];
    if(cell==nil) {
        NSArray* arr = [[NSBundle mainBundle] loadNibNamed:@"ChatInfoTableViewCell" owner:self options:nil];
        for (id obj in arr) {
            if ([obj isKindOfClass:[ChatInfoTableViewCell class]]) {
                cell = (ChatInfoTableViewCell*)obj;
            }
        }
    }
    
    // 利表格单元对应的数据对象对ui进行设置
    cell.lbContent.text = item.content;
    int colorType = item.colorType;
    UIColor *cellColor = nil;
    switch(colorType)
    {
        case TABLE_CELL_COLOR_BLUE:
            cellColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:255/255.0f alpha:1];
            break;
        case TABLE_CELL_COLOR_BRIGHT_RED:
            cellColor = [UIColor colorWithRed:255/255.0f green:0/255.0f blue:255/255.0f alpha:1];
            break;
        case TABLE_CELL_COLOR_RED:
            cellColor = [UIColor colorWithRed:255/255.0f green:0/255.0f blue:0/255.0f alpha:1];
            break;
        case TABLE_CELL_COLOR_GREEN:
            cellColor = [UIColor colorWithRed:0/255.0f green:128/255.0f blue:0/255.0f alpha:1];
            break;
        case TABLE_CELL_COLOR_BLACK:
        default:
            cellColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1];
            break;
    }
    if(cellColor != nil)
        cell.lbContent.textColor = cellColor;
    
    // ** 设置cell的lable高度
    CGRect rect = [cell.textLabel textRectForBounds:cell.textLabel.frame limitedToNumberOfLines:0];
    // 設置顯示榘形大小
    rect.size = [self _calculateCellSize:indexPath];
    // 重置列文本區域
    cell.lbContent.frame = rect;
    
    return cell;
}

// 点击表格行时要调用的方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do nothing
    
    // 自动取消选中状态，要不然看起来很丑
    [self performSelector:@selector(deselectTableViewCell) withObject:nil afterDelay:0.5f];
}

- (void)deselectTableViewCell
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
}
//=============================================================================== 有关主界面表格的托管实现方法 END

@end