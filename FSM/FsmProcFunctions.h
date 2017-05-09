//
//  FsmProcFunctions.h
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#ifndef __FSM_PROC_FUNCTIONS_H__
#define __FSM_PROC_FUNCTIONS_H__

#import "FSM.h"
#import "DataDef.h"

void makeFsm(CFsm &fsm);

extern void onDataRecvIPC(int nWidth, int nHeight, int nPcmFlag, unsigned char byChannel, unsigned char byType, unsigned short nRes, unsigned char *pData,     \
                   int nLen, unsigned char byIFrame, int nFrameRate, int nFactoryType, long lSessionId, long long lldDeviceAndChannelId, int nEncodeType,      \
                          unsigned int uYear, unsigned int uMonth, unsigned int uDay, unsigned int uHour, unsigned int uMinute, unsigned int uSecond);

extern void onDataRecvSimulateIPC(int nWidth, int nHeight, int nPcmFlag, unsigned char byChannel, unsigned char byType, unsigned short nRes,                   \
                           unsigned char *pData, int nLen, unsigned char byIFrame, int nFrameRate, int nFactoryType, long lSessionId,                          \
                                  long long lldDeviceAndChannelId, int nEncodeType, unsigned int uYear, unsigned int uMonth, unsigned int uDay,                \
                                  unsigned int uHour, unsigned int uMinute, unsigned int uSecond);

extern void onCommandRecv(int nCmd, long nSessionID, int nChannelID, long nFrameRate, int nBitRate, int nWidth, int nHeight, int nParam, char *pszData1,        \
                   char *pszData2, char *pszData3);

extern void onP2PStatus(int nValue, long nSessionID, int nStatus, char *pDestUUID, long context, long long lldDeviceAndChannelId);

extern void onExtCommandRecv(long nContext, const char *pDstUuid, const char *pData, unsigned int nLen);

extern void onPlayBackStatus(long sessionId, long long userdata, int cmd);

#endif	//__FSM_PROC_FUNCTIONS_H__
