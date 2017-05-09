//
//  FsmProcFunctions.mm
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//

#import "FsmProcFunctions.h"

#import "FSM.h"
#import "Configs.h"
#import "P2P_SDK.h"
#import "ToolBox.h"
#import "platform.h"
#import "GWPublic.h"
#import "gwErrCode.h"
#import "WebManager.h"
#import "AppDelegate.h"
#import "Toast+UIView.h"
#import "Mp4RecordManager.h"
#import "Pcm2AacEncoder_v2.h"
#import "FFMpegH264Decoder.h"
#import "FFMpegH264Encoder.h"
#import "Pcm2AacSoftEncoder.h"
#import "Aac2PcmSoftDecoder.h"
#import "../AudioQueue/AudioUnitIOMgr.h"
#import "DiscMoviePlayController_v2.h"
#import "AFHTTPRequestOperationManager.h"
#import "MNMetaDataTool.h"
#import "PlayTaskViewController.h"
#import "ManNiuSDKManager.h"
#import "DBManager.h"
#import "LogManager.h"
#import "AppDataCenter.h"
#import "PlayTaskManager.h"
#import "CloudViewController.h"


bool checkIfIDMCanLogin(CFsm_Event &event);
bool closeRealplay(CFsm_Event &event);

extern void FsmStateAppStartingUpEntryAction           (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateStartedUpIdleEnteryAction          (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateWebAccoutSignInOkEnteryAction      (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateLoginingEtsIdmEntryAction          (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateLoginingEtsIdmWorkAction           (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateEtsIdmLoginFailedEntryAction       (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateEtsIdmLoginOkEntryAction           (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateRealPlayingClientEntryAction       (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateRealPlayingClientExitAction        (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateWebAccoutSigningOutEntryAction     (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateWebAccoutSignOutOkEntryAction      (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateClientOnlineIdleEntryAction        (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateAppEnteredBackgroundEntryAction    (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateAppRestoringFromBkgEntryAction     (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateEtsOrIdmDisconnectedEnteryAction   (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStatePrepare2StartSimulateIPCEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateNetDisconnectedEntryAction         (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateAppResignedActiveEntryAction       (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
extern void FsmStateAppBecomeActiveEntryAction         (CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);


/**
 *  Description : 构建APP状态机
 *
 *  @param fsm  : APP 状态机
 */
void makeFsm(CFsm &fsm){
    CFsm_State *pState = NULL;
    
    fsm.m_pStartState->AddTranslate(FSM_EVENT_APP_STARTUP,                  FSM_STATE_APP_STARTING_UP,                      NULL);
    // 2    FSM_STATE_APP_STARTING_UP
    pState = fsm.AddState(FSM_STATE_APP_STARTING_UP,                        FsmStateAppStartingUpEntryAction,               NULL, NULL);
    pState->AddTranslate(FSM_EVENT_APP_INIT_COMPLETE,                       FSM_STATE_APP_STARTED_UP_IDLE,                  NULL);
    
    // 3    FSM_STATE_APP_STARTED_UP_IDLE
    pState = fsm.AddState(FSM_STATE_APP_STARTED_UP_IDLE,                    FsmStateStartedUpIdleEnteryAction,              NULL, NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGIN,                        FSM_STATE_WEB_ACCOUT_SIGNNING_IN,               NULL);
    
    // 4    FSM_STATE_WEB_ACCOUT_SIGNNING_IN
    pState = fsm.AddState(FSM_STATE_WEB_ACCOUT_SIGNNING_IN,                 NULL,                                           NULL, NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_VERIFY_ERROR,                 FSM_STATE_WEB_ACCOUT_SIGNIN_FAILED,             NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_VERIFY_OK,                    FSM_STATE_WEB_ACCOUT_SIGNIN_OK,                 NULL);
    
    // 5    FSM_STATE_WEB_ACCOUT_SIGNIN_OK
    pState = fsm.AddState(FSM_STATE_WEB_ACCOUT_SIGNIN_OK,                   FsmStateWebAccoutSignInOkEnteryAction,          NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ETS_IDM_START_LOGIN,                     FSM_STATE_LOGINING_ETS_IDM,                     checkIfIDMCanLogin);
    
    // 6   FSM_STATE_LOGINING_ETS_IDM
    pState = fsm.AddState(FSM_STATE_LOGINING_ETS_IDM,                       FsmStateLoginingEtsIdmEntryAction,              FsmStateLoginingEtsIdmWorkAction, NULL);
    pState->AddTranslate(FSM_EVENT_ETS_IDM_LOGIN_FAILED,                    FSM_STATE_LOGIN_ETS_IDM_FAILED,                 NULL);
    pState->AddTranslate(FSM_EVENT_ETS_IDM_LOGIN_OK,                        FSM_STATE_LOGIN_ETS_IDM_OK,                     NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT,                       FSM_STATE_WEB_ACCOUT_SIGNING_OUT,               NULL);
    
    // 7   FSM_STATE_LOGIN_ETS_IDM_FAILED
    pState = fsm.AddState(FSM_STATE_LOGIN_ETS_IDM_FAILED,                   FsmStateEtsIdmLoginFailedEntryAction,           NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ANONYMOUS,                               FSM_STATE_LOGINING_ETS_IDM,                     NULL);
    pState->AddTranslate(FSM_EVENT_APP_ETS_IDM_RELOGIN,                     FSM_STATE_LOGINING_ETS_IDM,                     checkIfIDMCanLogin);
    pState->AddTranslate(FSM_EVENT_NET_CONNECTED,                           FSM_STATE_LOGINING_ETS_IDM,                     NULL);
    pState->AddTranslate(FSM_EVENT_APP_WILL_RESIGN_ACTIVE,                  FSM_STATE_APP_RESIGNED_ACTIVE,                  NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT,                       FSM_STATE_WEB_ACCOUT_SIGNING_OUT,               NULL);
    
    // 8   FSM_STATE_LOGIN_ETS_IDM_OK
    pState = fsm.AddState(FSM_STATE_LOGIN_ETS_IDM_OK,                       FsmStateEtsIdmLoginOkEntryAction,               NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ANONYMOUS,                               FSM_STATE_CLIENT_ONLINE_IDLE,                   NULL);
    
    // 9   FSM_STATE_WEB_ACCOUT_SIGNING_OUT
    pState = fsm.AddState(FSM_STATE_WEB_ACCOUT_SIGNING_OUT,                 FsmStateWebAccoutSigningOutEntryAction,         NULL, NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT_OK,                    FSM_STATE_WEBACCOUT_SIGNOUT_OK,                 NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT_FAILED,                FSM_STATE_CLIENT_ONLINE_IDLE,                   NULL);
    
    // 10   FSM_STATE_WEBACCOUT_SIGNOUT_OK
    pState = fsm.AddState(FSM_STATE_WEBACCOUT_SIGNOUT_OK,                   FsmStateWebAccoutSignOutOkEntryAction,          NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ANONYMOUS,                               FSM_STATE_APP_STARTED_UP_IDLE,                  NULL);
    
    // 11   FSM_STATE_WEB_ACCOUT_SIGNIN_FAILED
    pState = fsm.AddState(FSM_STATE_WEB_ACCOUT_SIGNIN_FAILED,               NULL,                                           NULL, NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGIN,                        FSM_STATE_WEB_ACCOUT_SIGNNING_IN,               NULL);
    
    // 12   FSM_STATE_CLIENT_ONLINE_IDLE
    pState = fsm.AddState(FSM_STATE_CLIENT_ONLINE_IDLE,                     FsmStateClientOnlineIdleEntryAction,            NULL, NULL);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT,                       FSM_STATE_WEB_ACCOUT_SIGNING_OUT,               NULL);
    pState->AddTranslate(FSM_EVENT_APP_WILL_RESIGN_ACTIVE,                  FSM_STATE_APP_RESIGNED_ACTIVE,                  NULL);
    pState->AddTranslate(FSM_EVENT_ETS_DISCONNECT,                          FSM_STATE_IDM_OR_ETS_DISCONNECTED,              NULL);
    pState->AddTranslate(FSM_EVENT_NET_DISCONNECTED,                        FSM_STATE_NET_DISCONNECTED,                     NULL);
    
    // 13   FSM_STATE_APP_ENTERED_BACKGROUND
    pState = fsm.AddState(FSM_STATE_APP_ENTERED_BACKGROUND,                 FsmStateAppEnteredBackgroundEntryAction,        NULL, NULL);
    pState->AddTranslate(FSM_EVENT_APP_WILL_ENTER_FOREGROUND,               FSM_STATE_APP_RESIGNED_ACTIVE,                  NULL);
    
    // 14   FSM_STATE_IDM_OR_ETS_DISCONNECTED
    pState = fsm.AddState(FSM_STATE_IDM_OR_ETS_DISCONNECTED,                FsmStateEtsOrIdmDisconnectedEnteryAction,       NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ANONYMOUS,                               FSM_STATE_LOGINING_ETS_IDM,                     checkIfIDMCanLogin);
    pState->AddTranslate(FSM_EVENT_WEB_ACCOUT_LOGOUT,                       FSM_STATE_WEB_ACCOUT_SIGNING_OUT,               NULL);
    
    // 15   FSM_STATE_NET_DISCONNECTED
    pState = fsm.AddState(FSM_STATE_NET_DISCONNECTED,                       FsmStateNetDisconnectedEntryAction,             NULL, NULL);
    pState->AddTranslate(FSM_EVENT_NET_CONNECTED,                           FSM_STATE_LOGINING_ETS_IDM,                     NULL);
    pState->AddTranslate(FSM_EVENT_APP_DID_ENTER_BACKGROUND,                FSM_STATE_APP_ENTERED_BACKGROUND,               NULL);
    pState->AddTranslate(FSM_EVENT_APP_DID_BECOME_ACTIVE,                   FSM_STATE_APP_BECOME_ACTIVE,                    NULL);
    
    // 16   FSM_STATE_APP_RESIGNED_ACTIVE
    pState = fsm.AddState(FSM_STATE_APP_RESIGNED_ACTIVE,                    FsmStateAppResignedActiveEntryAction,           NULL, NULL);
    pState->AddTranslate(FSM_EVENT_APP_DID_ENTER_BACKGROUND,                FSM_STATE_APP_ENTERED_BACKGROUND,               NULL);
    pState->AddTranslate(FSM_EVENT_APP_DID_BECOME_ACTIVE,                   FSM_STATE_APP_BECOME_ACTIVE,                    NULL);
    pState->AddTranslate(FSM_EVENT_NET_DISCONNECTED,                        FSM_STATE_APP_RESIGNED_ACTIVE,                  NULL);
    pState->AddTranslate(FSM_EVENT_NET_CONNECTED,                           FSM_STATE_APP_RESIGNED_ACTIVE,                  NULL);
    
    // 17   FSM_STATE_APP_BECOME_ACTIVE
    pState = fsm.AddState(FSM_STATE_APP_BECOME_ACTIVE,                      FsmStateAppBecomeActiveEntryAction,             NULL, NULL);
    pState->AddTranslate(FSM_EVENT_ETS_IDM_LOGIN_FAILED,                    FSM_STATE_LOGIN_ETS_IDM_FAILED,                 NULL);
    pState->AddTranslate(FSM_EVENT_ETS_IDM_LOGIN_OK,                        FSM_STATE_LOGIN_ETS_IDM_OK,                     NULL);
    pState->AddTranslate(FSM_EVENT_ACCOUNT_LOGIN_IN_OTHER_DEVICE,           FSM_STATE_IDM_OR_ETS_DISCONNECTED,              NULL);
    
    fsm.RegisterNames(FSM_STATE_NAMES, FSM_STATE_COUNT, FSM_EVENT_NAMES, FSM_EVENT_COUNT);
    
    DEBUG_INFO("FSM constructed completely.\n");
}


#pragma mark FSM Action Functions
void FsmStateAppStartingUpEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    int nRetCode = 0;
    AppConfig *config = nil;
    
    nRetCode = Ios_P2P_SDK_Init(NULL);
    GW_PROCESS_ERROR(0 == nRetCode);
    
    [AppDataCenter sharedInstance]->m_bIDMFirstTimeLoginFlag = NO;
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [[DBManager sharedInstance] updateLocalDB];
    GW_PROCESS_ERROR([[LogManager sharedInstance] setupSdkLogPath]);
    
    [AppDataCenter sharedInstance].m_pUserInfo = [[UserInfo alloc] init];
    [AppDataCenter sharedInstance].m_pConfig = [[AppConfig alloc] init];
    
    [AppDataCenter sharedInstance].m_pConfig.m_pRedirectAddr = @"www.mny9.com:80";
    if ([[[AppDataCenter sharedInstance].m_pLoginInfo.m_pNcCode uppercaseString] isEqualToString:@"TJ"])
        [AppDataCenter sharedInstance].m_pConfig.m_pRedirectAddr = @"tj.mny9.com:80";
    
    config = [AppDataCenter sharedInstance].m_pConfig;
    nRetCode = [DBManager readConfig:&config];
    GW_PROCESS_ERROR(0 == nRetCode);
    
    [AppDataCenter sharedInstance].m_pConfig.m_pRedirectAddr = @"www.mny9.com:80";
    if ([[[AppDataCenter sharedInstance].m_pLoginInfo.m_pNcCode uppercaseString] isEqualToString:@"TJ"])
        [AppDataCenter sharedInstance].m_pConfig.m_pRedirectAddr = @"tj.mny9.com:80";
    [[AppDelegate shareDelegate] onEventAppStartUp];
    
//    fsm.PushEvent(FSM_EVENT_APP_INIT_COMPLETE, 0);
    
Exit0:
    return ;
}

void FsmStateStartedUpIdleEnteryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    BOOL bEmptyUserName = event.m_uParam == 1 ? YES : NO;
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[AppDelegate shareDelegate] jump2LoginInterface:bEmptyUserName];
    });
}

void FsmStateWebAccoutSignInOkEnteryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    sEventParam *pParam = (sEventParam *)event.m_uParam;
    NSString *pUserName = [NSString stringWithUTF8String:pParam->szUserName];
    NSString *pPassword = [NSString stringWithUTF8String:pParam->szPassword];
    NSString *pCountryCode = [NSString stringWithUTF8String:pParam->szCountryCode];
    NSString *pNCCode = [NSString stringWithUTF8String:pParam->szNCCode];

    [DBManager writeUserNameWith:pUserName Password:pPassword countryCode:pCountryCode NCCode:pNCCode];
    [[AppDelegate shareDelegate] setupPersonalDocument:pUserName];
    [[AppDelegate shareDelegate] onEventAccoutLogined];
    
    NSMutableArray *pArrDevicesInfo = nil;
    [DBManager readDeviceListFromDB:&pArrDevicesInfo];
    [[DevManager sharedInstance] reloadDevicesByInfo:pArrDevicesInfo];
}

bool checkIfIDMCanLogin(CFsm_Event &event){
    return [AppDataCenter sharedInstance]->m_bLogoutMsgAlreadyRecved ? false : true;
}

bool closeRealplay(CFsm_Event &event){
    [[DevManager sharedInstance] stopAllRealplay];
    
    return true;
}

void FsmStateLoginingEtsIdmEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    
}

void FsmStateLoginingEtsIdmWorkAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    int nRetCode = -1;
    nRetCode = [[ManNiuSdkManager sharedInstance] login:(char *)[[AppDataCenter sharedInstance].m_pUserInfo.m_pSID UTF8String] Type:3];
    
    if (nRetCode != 0){
        fsm.PushEvent(FSM_EVENT_ETS_IDM_LOGIN_FAILED, 0);
    }else{
        fsm.PushEvent(FSM_EVENT_ETS_IDM_LOGIN_OK, 0);
    }
}

void FsmStateEtsIdmLoginFailedEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    [AppDataCenter sharedInstance]->m_nETSFailedTimes ++;
    
    if (![AppDataCenter sharedInstance]->m_bAccountSigningOut){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            fsm.PushEvent(FSM_EVENT_APP_ETS_IDM_RELOGIN, 0);
            
            DEBUG_INFO("ETS & IDM 重新登录...\n");
        });
    }
}

void FsmStateEtsIdmLoginOkEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    static int nThreadNum = 0;
    [AppDataCenter sharedInstance]->m_nETSFailedTimes = 0;
    [AppDataCenter sharedInstance]->mEtsIdmConnected = YES;
    
    if (![AppDataCenter sharedInstance]->m_bIDMFirstTimeLoginFlag){
        [AppDataCenter sharedInstance]->m_bIDMFirstTimeLoginFlag = YES;
    }
    
    dispatch_queue_t queue = dispatch_queue_create("heartbeat", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        [[NSThread currentThread] setName:[NSString stringWithFormat:@"thread:%d", ++nThreadNum]];
        [[ManNiuSdkManager sharedInstance] startHeartBeat];
    });
    
    fsm.PushEvent(FSM_EVENT_ANONYMOUS, 0);
}

//void FsmStateApplyingRealplayEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
//    int nExitCode    = -1;
//    int nRetCode     = -1;
//    Device *device   = nil;
//    DeviceInfo *pDeviceInfo = nil;
//    sPlayInfo *pPlayInfo = (sPlayInfo *)event.m_uParam;
//    
//    if (fsm.GetCurStateID() != FSM_STATE_CLIENT_ONLINE_IDLE){
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            CloudViewController *vc = [[CloudViewController alloc]init];
//            [[AppDelegate shareDelegate].m_pCloudViewController.view makeToast:NSLocalizedString(@"system_uncomplete", @"系统未准备完毕，请稍等")];
//        });
//        
//        GW_PROCESS_SUCCESS(true);
//    }
//    
//    device = [[DevManager sharedInstance] getDeviceBySid:[NSString stringWithFormat:@"%s", pPlayInfo->szSID]];
//    GW_PROCESS_ERROR(device);
//    
//    pDeviceInfo = device->m_pInfo;
//    
//    // 如果是收藏设备
//    if ([pDeviceInfo.m_pCollected isEqualToNumber:@1]){
//        DiscMoviePlayController_v2 *pNextController = [[DiscMoviePlayController_v2 alloc] initWithNibName:@"DiscMoviePlayController_v2" bundle:nil];
//        pNextController->m_pLiveUrlString = [NSString stringWithFormat:@"http://%@/NineCloud/LiveAction_toPlays?lc.deviceId=%@", [AppDataCenter sharedInstance].m_pConfig.m_pWebRootAddr, pDeviceInfo.m_pSID];
//        pNextController->m_pLiveID = [pDeviceInfo.m_pSID copy];
//        CloudViewController *vc = [[CloudViewController alloc]init];
//        pNextController->m_pPrevController = vc.navigationController;
//        
//        UINavigationController *presNavigation = [[UINavigationController alloc] initWithRootViewController:pNextController];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            CloudViewController *vc = [[CloudViewController alloc]init];
//            [vc presentViewController:presNavigation animated:YES completion:nil];
//        });
//        
//        fsm.PushEvent(FSM_EVENT_CLOUD_COLLECTION_PLAY, 0);
//    }else{
//        if ([pDeviceInfo.m_pType isEqualToNumber:@4]){
//            [AppDataCenter sharedInstance]->m_eRealPlayType = LIVE_TYPE_PHONE;
//            Ios_P2P_SDK_SetCallback(onDataRecvSimulateIPC, onCommandRecv, onP2PStatus, onExtCommandRecv, onTunnel, onPlayBackStatus);
//        }else if ([pDeviceInfo.m_pType isEqualToNumber:@1]){
//            [AppDataCenter sharedInstance]->m_eRealPlayType = LIVE_TYPE_IPC;
//            // Ios_P2P_SDK_SetCallback(onDataRecvIPC, onCommandRecv, onP2PStatus);
//        }
//        [AppDataCenter sharedInstance]->m_nMeType = NATIVE_TYPE_WATCH_LIVE;
//        [AppDataCenter sharedInstance]->m_pDeviceName = pDeviceInfo.m_pDevicesName;
//        
//        NSString *sid = [NSString stringWithFormat:@"%s", pPlayInfo->szSID];
//        int nChannelId = pPlayInfo->nChannelId;
//        STREAM_MODE_TYPE eNetMode = pPlayInfo->eStreamMode;
//        
//        dispatch_queue_t myQueue = dispatch_queue_create("asdasd", DISPATCH_QUEUE_SERIAL);
//        dispatch_async(myQueue, ^{
//            long long lldDeviceAndChannelId = 0;
//            int nRetCode = [[DevManager sharedInstance] startRealplayWithDeviceSid:sid channel:nChannelId netMode:eNetMode p2pId:[AppDataCenter sharedInstance]->mP2pIds[0] lldDeviceAndChannelId:lldDeviceAndChannelId];
//            
//            if (0 != nRetCode){
//                NSLog(@"lldDeviceAndChannelId = %lld, %d, %s", lldDeviceAndChannelId, [DevManager getP2pPurposeType:lldDeviceAndChannelId], __FUNCTION__);
//                [[AppDelegate shareDelegate] pushEvent:FSM_EVENT_P2P_CONNECT_ERROR uParam:nRetCode lldParam:lldDeviceAndChannelId];
//            }
//        });
//    }
//    
//Exit1:
//    nExitCode = 0;
//Exit0:
//    GW_DELETE(pPlayInfo);
//    
//    if (0 != nExitCode){
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            CloudViewController *vc = [[CloudViewController alloc]init];
//            [vc.view makeToast:[NSString stringWithFormat:NSLocalizedString(@"live_play_failed:ERR=%d", @"直播失败:ERR=%d"), nRetCode]];
//        });
//    }
//    
//    return ;
//}

void FsmStateRealPlayingClientEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    
 //   [[AppDelegate shareDelegate].m_pCloudViewController jump2LivePlay];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[AppDelegate shareDelegate] Test];
//    });
}

void FsmStateRealPlayingClientExitAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    [LogManager log2File:@"FsmStateRealPlayingClientExitAction 进\n"];
    [[DevManager sharedInstance] stopAllRealplay];
    [LogManager log2File:@"FsmStateRealPlayingClientExitAction ###\n"];
//    CloudViewController *vc = [[CloudViewController alloc]init];
//    [vc exitLivePlay];
    [LogManager log2File:@"FsmStateRealPlayingClientExitAction 出\n"];
//    // 停止音频播放
//    AudioQueuePcmPlayer::sharedInstance()->Stop();
//    AudioQueuePcmPlayer::sharedInstance()->Uninit();
}

void FsmStateWebAccoutSigningOutEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    AppDelegate *APP = nil;
    APP = [AppDelegate shareDelegate];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        APP->m_pHUD = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow   /*APP.m_pCurViewController.view*/];
        APP->m_pHUD.delegate = APP;
        APP->m_pHUD.labelText = NSLocalizedString(@"signing_out", @"正在退出账号");
        [[UIApplication sharedApplication].keyWindow addSubview:APP->m_pHUD];
        [APP->m_pHUD showWhileExecuting:@selector(onLogoutAccout) onTarget:APP withObject:nil animated:YES];
    });
}

void FsmStateWebAccoutSignOutOkEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    [AppDataCenter sharedInstance]->m_bIDMFirstTimeLoginFlag = NO;
    [AppDataCenter sharedInstance]->m_bAccountSigningOut = NO;
    
    // 登出账号，清理数据
    [[DevManager sharedInstance] clearDevices];
    
    Ios_P2P_SDK_Logout();
    
    fsm.PushEvent(FSM_EVENT_ANONYMOUS, 1);
}

void FsmStateRealPlayExitingEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    // 停止录制音视频
    [[Mp4RecordManager sharedInstance] stopRecord];
    
    fsm.PushEvent(FSM_EVENT_REALPLAY_EXITED, 0);
}

void FsmStateClientOnlineIdleEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    DEBUG_INFO("ALL SERVERS SIGNED IN!! ^_^\n");
}

void FsmStateAppEnteredBackgroundEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    [[PlayTaskManager sharedInstance] resetTasks];
    
    if ([AppDataCenter sharedInstance]->m_bEtsIdmConnected){
        Ios_P2P_SDK_Logout();
        [AppDataCenter sharedInstance]->m_bEtsIdmConnected = NO;
    }
}

void FsmStateAppRestoringFromBkgEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    if (![AppDataCenter sharedInstance]->m_bEtsIdmConnected){
        [[ManNiuSdkManager sharedInstance] login:(char *)[[AppDataCenter sharedInstance].m_pUserInfo.m_pSID UTF8String] Type:3];
        
        fsm.PushEvent(FSM_EVENT_ANONYMOUS, 0);
    }
}

void FsmStateEtsOrIdmDisconnectedEnteryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    Ios_P2P_SDK_Logout();
    
    [AppDataCenter sharedInstance]->mEtsIdmConnected = NO;
    
    if (![AppDataCenter sharedInstance]->m_bLogoutMsgAlreadyRecved){
        fsm.PushEvent(FSM_EVENT_ANONYMOUS, 0);
    }
}

void FsmStateNetDisconnectedEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    if ([AppDataCenter sharedInstance]->m_bEtsIdmConnected){
        Ios_P2P_SDK_Logout();
        [AppDataCenter sharedInstance]->m_bEtsIdmConnected = NO;
    }
}

void FsmStateAppResignedActiveEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    // FSM_STATE_APP_ENTERED_BACKGROUND -> FSM_STATE_APP_RESIGNED_ACTIVE
    if (FSM_STATE_APP_ENTERED_BACKGROUND == segue.m_nSourceStateID){
        if (![AppDataCenter sharedInstance]->m_bEtsIdmConnected && ![AppDataCenter sharedInstance]->m_bLogoutMsgAlreadyRecved){
            [[ManNiuSdkManager sharedInstance] login:(char *)[[AppDataCenter sharedInstance].m_pUserInfo.m_pSID UTF8String] Type:3];
        }
    }
    else if (FSM_STATE_APP_RESIGNED_ACTIVE == segue.m_nSourceStateID && FSM_EVENT_NET_CONNECTED == event.m_nID){
        if (![AppDataCenter sharedInstance]->m_bEtsIdmConnected){
            [[ManNiuSdkManager sharedInstance] login:(char *)[[AppDataCenter sharedInstance].m_pUserInfo.m_pSID UTF8String] Type:3];
        }
    }
    else if (FSM_STATE_APP_RESIGNED_ACTIVE == segue.m_nSourceStateID && FSM_EVENT_NET_DISCONNECTED == event.m_nID){
        if ([AppDataCenter sharedInstance]->m_bEtsIdmConnected){
            Ios_P2P_SDK_Logout();
            
            [AppDataCenter sharedInstance]->m_bEtsIdmConnected = NO;
        }
    }
    
    // FSM_STATE_CLIENT_ONLINE_IDLE -> FSM_STATE_APP_RESIGNED_ACTIVE
    if (FSM_STATE_CLIENT_ONLINE_IDLE == segue.m_nSourceStateID){
    
    }
}

void FsmStateAppBecomeActiveEntryAction(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue){
    if ([AppDataCenter sharedInstance]->m_bLogoutMsgAlreadyRecved){
        [[AppDelegate shareDelegate] pushEvent:FSM_EVENT_ACCOUNT_LOGIN_IN_OTHER_DEVICE Param:0];
    }else if ([AppDataCenter sharedInstance]->m_bEtsIdmConnected){
        [[AppDelegate shareDelegate] pushEvent:FSM_EVENT_ETS_IDM_LOGIN_OK Param:0];
    }else{
        [[AppDelegate shareDelegate] pushEvent:FSM_EVENT_ETS_IDM_LOGIN_FAILED Param:0];
    }
    
    [[PlayTaskManager sharedInstance] restartTasks];
}
