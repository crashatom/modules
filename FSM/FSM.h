//
//  FSM.h
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#ifndef __FSM_H__
#define __FSM_H__

#include <map>
#include <list>
#include <queue>
#include <vector>
#include <semaphore.h>

#include "GWPublic.h"
#include "FsmState.h"
#include "FsmDataDef.h"
#include "LogManager.h"

#define EVENT_DATA_MAX_SIZE     64
#define MAX_TRANSLATE_NUM       64

class CFsm{
public:
    CFsm();
    ~CFsm();
    
public:
    void Init();
    void Start();
    void Terminate();
    
    bool ContainsEvent(int nID);
    bool GetLastEvent(int &event);
    int GetCurStateID();
    void CleanUpStateTriggers(long ID = 0);
    void CleanUpEventTriggers(long ID = 0);
    
public:
    void PushEvent(CFsm_Event &event);
    void PushEvent(int nID, unsigned long uParam, const char *pszParam = NULL);
    void PushEvent(int nID, unsigned long uParam, long long lldParam);
    
    CFsm_State *AddState(state_param &StateParam);
    CFsm_State *AddState(int nID, FSM_ACTION_FUNC entryAction, FSM_ACTION_FUNC workAction, FSM_ACTION_FUNC exitAction);
    CFsm_StateTrigger *PushStateTrigger(int nStateId, long ID, FSM_TRIGGER_TYPE type, FSM_ACTION action, FSM_STATE_TRIGGER_FUNC funcHandler, void *param, int nParam);
    CFsm_EventTrigger *PushEventTrigger(int nEventId, long ID, FSM_TRIGGER_TYPE type, FSM_EVENT_TRIGGER_FUNC funcHandler, void *param);
    
    bool RegisterStateEntryAction(int nID, FSM_ACTION_FUNC entryAction);
    bool RegisterStateExitAction(int nID, FSM_ACTION_FUNC exitAction);
    
    virtual void Run();
    void RegisterNames(char szStateNames[][64], int nStateNum, char szEventNames[][64], int nEventNum);
    
    const char *GetStateName(int nID);
    const char *GetEventName(int nID);
    
private:
    void SetCurStateID(int nStateID);
    void SetUnacceptAction(FSM_ACTION_FUNC func);
    void AddState(CFsm_State &state);
    // void EnterState(CFsm_Event &event, int nSourceStateID, int nTargetStateID);
    CFsm_State* EnterState(CFsm_Event &event, CFsm_Segue &segue);
    void ExitState(CFsm_Event &event, CFsm_Segue &segue);
    
    void *threadFunc(void *arg);
    
    int HandleEvent(CFsm_Event &event);
    int AddStateTable(STATE_TABLE stable);
    void onStateTriggerOff(int nStateID, FSM_ACTION action, CFsm_Segue &segue);
    void onEventTriggerOff(CFsm_Event &event);
    
    
    
private:
    int m_nCurStateID;
    int m_bNeedExit;
    FSM_ACTION_FUNC m_fnUnacceptAction;
    
public:
    CFsm_State *m_pStartState;
    CFsm_State *m_pEndState;
    
private:
    pthread_t m_thread;
    
    std::vector<CFsm_State *> m_vStates;
    // std::queue<CFsm_Event *> m_queEvents;
    std::list<CFsm_Event *> m_listEvents;
    
    std::list<CFsm_StateTrigger *> m_listStateTriggers;
    std::list<CFsm_EventTrigger *> m_listEventTriggers;
    
    pthread_mutex_t mStateMutex;
    pthread_mutex_t mEventMutex;
    
    sem_t *pEventSemaphore;
    
    char **m_pszStateNames;
    char **m_pszEventNames;
    
    
};

#endif	//_FSM_H__
