//
//  FSM.h
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#ifndef __KFSM_EVENT_H__
#define __KFSM_EVENT_H__

#include "GWPublic.h"
#include "FsmDataDef.h"

#define EVENT_DATA_MAX_SIZE     64
#define MAX_TRANSLATE_NUM       64

class CFsm;
class CFsm_Segue;

// 状态机事件优先级
typedef enum{
    FEL_TOP_MOST = 0,                   // 最高级别
    FEL_HIGH,                           // 高
    FEL_NORMAL,                         // 一般
    FEL_LOW,                            // 低
    
    FEL_COUNT,
}FSM_EVENT_LEVEL;

// 事件进出动作类型
typedef enum{
    FSM_ACTION_STATE_NONE = 0,
    FSM_ACTION_STATE_PREPARE_ENTER,
    FSM_ACTION_STATE_ENTERED,
    FSM_ACTION_STATE_PREPARE_EXIT,
    FSM_ACTION_STATE_EXITED,
    
    FSM_ACTION_COUNT,
}FSM_ACTION;

typedef enum{
    FSM_TRIGGER_TYPE_NONE = 0,
    FSM_TRIGGER_TYPE_PERMANENT,   // 永久触发，直到被CleanUp
    FSM_TRIGGER_TYPE_ONCE,        // 只触发一次
    
    FSM_TRIGGER_COUNT,
}FSM_TRIGGER_TYPE;

class CFsm_Event{
    
public:
    int m_nID;
    char szParam[64];
    unsigned long m_uParam;
    long long m_lldParam;
    FSM_EVENT_LEVEL m_ePriority;
    
    CFsm_Event(){
        m_nID = 0;
        m_uParam = 0;
        m_ePriority = FEL_NORMAL;
    }
};

typedef void (*FSM_ACTION_FUNC)(CFsm &fsm, CFsm_Event &event, CFsm_Segue &segue);
typedef bool (*FSM_TRANSLATE_CHECK_FUNC)(CFsm_Event &event);
typedef void (*FSM_STATE_TRIGGER_FUNC)(CFsm &fsm, int nStateID, long lTriggerId, FSM_ACTION action, CFsm_Segue &segue, void *contextRef, int nParam);
typedef void (*FSM_EVENT_TRIGGER_FUNC)(CFsm &fsm, int nEventID, long lTriggerId, void *contextRef, int nParam, long long lldParam);

class CFsm_StateTrigger{
public:
    
    CFsm_StateTrigger(){
        m_lTriggerId  = 0;
        m_nStateID    = 0;
        m_nParam      = 0;
        contextRef    = NULL;
        funcHandler   = NULL;
        m_eActionType = FSM_ACTION_STATE_NONE;
    }
    
public:
    int m_nStateID;
    int m_nParam;
    long m_lTriggerId;
    FSM_ACTION m_eActionType;
    FSM_STATE_TRIGGER_FUNC funcHandler;
    void *contextRef;
    FSM_TRIGGER_TYPE m_eType;
};

class CFsm_EventTrigger{
public:
    CFsm_EventTrigger(){
        m_lTriggerId  = 0;
        m_nEventID    = 0;
        m_nParam      = 0;
        contextRef    = NULL;
        funcHandler   = NULL;
        m_eType       = FSM_TRIGGER_TYPE_ONCE;
    }
    
    int m_nEventID;
    int m_nParam;
    long m_lTriggerId;
    FSM_EVENT_TRIGGER_FUNC funcHandler;
    void *contextRef;
    FSM_TRIGGER_TYPE m_eType;
};

#endif	//_FSM_H__
