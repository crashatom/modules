//
//  FSM.mm
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#include <pthread.h>
#include "FSM.h"

#define FSM_EVENT_SEMAPHORE   "FsmEventSem"

CFsm::CFsm(){
    m_thread = NULL;
    m_pszStateNames = NULL;
    m_pszEventNames = NULL;
    
    m_listEvents.clear();
    m_listEventTriggers.clear();
    m_listStateTriggers.clear();
    
    pEventSemaphore = sem_open(FSM_EVENT_SEMAPHORE, O_CREAT, S_IRUSR | S_IWUSR, 0);
}

CFsm::~CFsm(){
    GW_DELETE_ARRAY(m_pszStateNames);
    GW_DELETE_ARRAY(m_pszEventNames);
    
    sem_close(pEventSemaphore);
    sem_unlink(FSM_EVENT_SEMAPHORE);
}

void CFsm::Init(){
    m_bNeedExit = false;
    m_pStartState = this->AddState(FSM_STATE_START, NULL, NULL, NULL);
    m_pEndState = this->AddState(FSM_STATE_END, NULL, NULL, NULL);
    
    SetCurStateID(FSM_STATE_START);
    
    pthread_mutex_init(&mEventMutex, NULL);
    pthread_mutex_init(&mStateMutex, NULL);
}

void CFsm::SetCurStateID(int nID){
	m_nCurStateID = nID;
}

int CFsm::GetCurStateID(){
	return m_nCurStateID;
}

// EnterState(CFsm_Event &event, int nStateID)
// void CFsm::EnterState(CFsm_Event &event, int nSourceStateID, int nTargetStateID)
CFsm_State *CFsm::EnterState(CFsm_Event &event, CFsm_Segue &segue){
	CFsm_State *pkTargetState = NULL;

    int nTargetStateID = segue.m_nTargetStateID;
    
    onStateTriggerOff(nTargetStateID, FSM_ACTION_STATE_PREPARE_ENTER, segue);
    
	if (nTargetStateID != FSM_STATE_END){
		pkTargetState = m_vStates[nTargetStateID];
        
		pkTargetState->EntryAction(event, segue);
	}
	m_nCurStateID = nTargetStateID;
    DEBUG_INFO("INFO: current state %d(%s) entered.\n", m_nCurStateID, GetStateName(m_nCurStateID));
    
    [LogManager log2File:[NSString stringWithFormat:@"INFO: current state %d(%s) entered.\n", m_nCurStateID, GetStateName(m_nCurStateID)]];
    
    return pkTargetState;
}

void CFsm::ExitState(CFsm_Event &event, CFsm_Segue &segue){
    CFsm_State *pkSourceState = NULL;
    
    int nSourceStateID = segue.m_nSourceStateID;
    
    onStateTriggerOff(nSourceStateID, FSM_ACTION_STATE_PREPARE_EXIT, segue);
    
    if (nSourceStateID != FSM_STATE_START){
        pkSourceState = m_vStates[nSourceStateID];
        
        pkSourceState->ExitAction(event, segue);
    }
    
    DEBUG_INFO("INFO: current state %d(%s) exited.\n", nSourceStateID, GetStateName(nSourceStateID));
    
    [LogManager log2File:[NSString stringWithFormat:@"INFO: current state %d(%s) exited.\n", nSourceStateID, GetStateName(nSourceStateID)]];
}

void CFsm::PushEvent(CFsm_Event &event){
    DEBUG_INFO("INFO: push event %d(%s), current state is %d(%s)", event.m_nID, GetEventName(event.m_nID), m_nCurStateID, GetStateName(m_nCurStateID));
    
    [LogManager log2File:[NSString stringWithFormat:@"INFO: push event %d(%s), current state is %d(%s)\n", event.m_nID, GetEventName(event.m_nID), m_nCurStateID, GetStateName(m_nCurStateID)]];
    
    m_listEvents.push_back(&event);
    
    sem_post(pEventSemaphore);
}

void CFsm::PushEvent(int nID, unsigned long uParam, const char *pszParam){
    DEBUG_INFO("INFO: push event %d(%s), current state is %d(%s)", nID, GetEventName(nID), m_nCurStateID, GetStateName(m_nCurStateID));
    
    [LogManager log2File:[NSString stringWithFormat:@"INFO: push event %d(%s), current state is %d(%s)\n", nID, GetEventName(nID), m_nCurStateID, GetStateName(m_nCurStateID)]];
    
    CFsm_Event *pEvent = new CFsm_Event;
    pEvent->m_nID = nID;
    pEvent->m_uParam = uParam;
    if (pszParam != NULL){
        strncpy(pEvent->szParam, pszParam, sizeof(pEvent->szParam));
    }
    
    m_listEvents.push_back(pEvent);
    
    sem_post(pEventSemaphore);
}

void CFsm::PushEvent(int nID, unsigned long uParam, long long lldParam){
    DEBUG_INFO("INFO: push event %d(%s), current state is %d(%s)", nID, GetEventName(nID), m_nCurStateID, GetStateName(m_nCurStateID));
    
    [LogManager log2File:[NSString stringWithFormat:@"INFO: push event %d(%s), current state is %d(%s)\n", nID, GetEventName(nID), m_nCurStateID, GetStateName(m_nCurStateID)]];
    
    CFsm_Event *pEvent = new CFsm_Event;
    
    pEvent->m_nID = nID;
    pEvent->m_uParam = uParam;
    pEvent->m_lldParam = lldParam;
    
    m_listEvents.push_back(pEvent);

    sem_post(pEventSemaphore);
}

bool CFsm::ContainsEvent(int nID){
    
    for (std::list<CFsm_Event *>::iterator it = m_listEvents.begin(); it != m_listEvents.end(); it++){
        CFsm_Event *pEvent = *it;
        
        if (nID == pEvent->m_nID){
            return true;
        }
    }
    
    return false;
}

bool CFsm::GetLastEvent(int &event){
    if (m_listEvents.size() <= 0)
        return false;
    
    CFsm_Event *pEvent = m_listEvents.back();
    
    return pEvent->m_nID;
}

int CFsm::HandleEvent(CFsm_Event &event){
	int nExitCode = 0;
    
	int nNextStateID = FSM_STATE_END;
    
    CFsm_Segue *pSegue = NULL;
    CFsm_State *pState = NULL;
    // 事件触发器
    onEventTriggerOff(event);
    
    // 根据当前状态id，确定当前状态实例
	CFsm_State *pCurState = m_vStates[m_nCurStateID];
    // 根据当前状态实例，和事件来确定下一个状态
	pSegue = pCurState->HandleEvent(event, nNextStateID);
	GW_PROCESS_ERROR(pSegue != NULL);
    
    ExitState(event, *pSegue);
    // 状态触发器
    onStateTriggerOff(pCurState->m_nID, FSM_ACTION_STATE_EXITED, *pSegue);
    
    // 进入下一个状态
	pState = EnterState(event, *pSegue);
	// 状态触发器
    onStateTriggerOff(nNextStateID, FSM_ACTION_STATE_ENTERED, *pSegue);
    
    pState->WorkAction(event, *pSegue);
    
	nExitCode = 1;
Exit0:
	return nExitCode;
}

void *threadProc(void *arg){
    CFsm *pFsm = (CFsm *)arg;
    
    pFsm->Run();
    
    return NULL;
}

void CFsm::Start(){
    // WARNING: A fsm must run in one thread (different should be started in different thread).
    assert(m_thread == NULL);
    
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    pthread_create(&m_thread, &attr, threadProc, this);
    
    pthread_attr_destroy(&attr);
}

void CFsm::Terminate(){
    m_bNeedExit = true;
    
    pthread_join(m_thread, NULL);
    
    m_thread = NULL;
}

void CFsm::Run(){
    while(!m_bNeedExit){
        sem_wait(pEventSemaphore);
        
        if (m_listEvents.size() > 0){
            CFsm_Event *pEvent = m_listEvents.front();
            
            this->HandleEvent(*pEvent);
            this->m_listEvents.erase(m_listEvents.begin());
            
            delete pEvent;
            pEvent = NULL;
        }
    }
    
    printf("+++++++++++++++++++++++++++++++++++ 状态机结束 +++++++++++++++++++++++++++++++++++\n");
}

int CFsm::AddStateTable(STATE_TABLE stable){
	int nExitCode = 0;

	for (int i = 0; ; i++){
		if (FSM_STATE_END == stable[i].nID)
			break;
		CFsm_State *pkState = NULL;
		pkState = AddState(stable[i]);
		GW_PROCESS_ERROR(pkState);
	}
	nExitCode = 1;
Exit0:
	return nExitCode;
}

CFsm_State *CFsm::AddState(state_param &StateParam){
    CFsm_State *pkState = NULL;
    
    pkState = AddState(StateParam.nID, StateParam.EntryAction, StateParam.WorkAction, StateParam.ExitAction);
    GW_PROCESS_ERROR(pkState);
    
Exit0:
    
    return pkState;
}

CFsm_State *CFsm::AddState(int nID, FSM_ACTION_FUNC entryAction, FSM_ACTION_FUNC workAction, FSM_ACTION_FUNC exitAction){
    CFsm_State *pkState = NULL;
    
    pkState = new CFsm_State;
    GW_PROCESS_ERROR(pkState);
    
    pkState->m_nID = nID;
    pkState->m_pCFsm = this;
    pkState->SetEntryAction(entryAction);
    pkState->SetWorkAction(workAction);
    pkState->SetExitAction(exitAction);
    m_vStates.push_back(pkState);
    
Exit0:
    return pkState;
}

void CFsm::AddState(CFsm_State &state){
    m_vStates.push_back(&state);
}

CFsm_StateTrigger *CFsm::PushStateTrigger(int nStateId, long ID, FSM_TRIGGER_TYPE type, FSM_ACTION action, FSM_STATE_TRIGGER_FUNC funcHandler, void *param, int nParam){
    
    CFsm_StateTrigger *pTrigger = new CFsm_StateTrigger;
    
    pTrigger->m_nStateID = nStateId;
    pTrigger->funcHandler = funcHandler;
    pTrigger->contextRef = param;
    pTrigger->m_eActionType = action;
    pTrigger->m_nParam = nParam;
    pTrigger->m_eType = type;
    pTrigger->m_lTriggerId = ID;
    
    pthread_mutex_lock(&mStateMutex);
    
    m_listStateTriggers.push_back(pTrigger);
    
    pthread_mutex_unlock(&mStateMutex);
    
    return pTrigger;
}

CFsm_EventTrigger *CFsm::PushEventTrigger(int nEventId, long ID, FSM_TRIGGER_TYPE type, FSM_EVENT_TRIGGER_FUNC funcHandler, void *param){
    CFsm_EventTrigger *pTrigger = new CFsm_EventTrigger;
    
    pTrigger->m_nEventID = nEventId;
    pTrigger->funcHandler = funcHandler;
    pTrigger->contextRef = param;
    pTrigger->m_eType = type;
    pTrigger->m_lTriggerId = ID;
    
    pthread_mutex_lock(&mEventMutex);
    
    m_listEventTriggers.push_back(pTrigger);
    
    pthread_mutex_unlock(&mEventMutex);
    
    return pTrigger;
}

void CFsm::onStateTriggerOff(int nStateID, FSM_ACTION action, CFsm_Segue &segue){
    pthread_mutex_lock(&mStateMutex);
    
    std::list<CFsm_StateTrigger *>::iterator it = m_listStateTriggers.begin();
    
    for (; it != m_listStateTriggers.end(); it ++){
        CFsm_StateTrigger *trigger = *it;
        
        if (nStateID == trigger->m_nStateID && trigger->m_eActionType == action){
            if (trigger->funcHandler != NULL){
                printf("onStateTriggerOff开始\n");
                trigger->funcHandler(*this, nStateID, trigger->m_lTriggerId, action, segue, trigger->contextRef, trigger->m_nParam);
                printf("onStateTriggerOff结束\n");
            }
            
            if (trigger->m_eType == FSM_TRIGGER_TYPE_ONCE){
                delete trigger;
                
                m_listStateTriggers.erase(it--);
            }
        }
    }
    
    pthread_mutex_unlock(&mStateMutex);
}

void CFsm::onEventTriggerOff(CFsm_Event &event){
    

    pthread_mutex_lock(&mEventMutex);
    
    std::list<CFsm_EventTrigger *>::iterator it = m_listEventTriggers.begin();
    
    for (; it != m_listEventTriggers.end(); it++){
        CFsm_EventTrigger *trigger = *it;
        
        if (event.m_nID == trigger->m_nEventID){
            if (trigger->funcHandler != NULL){
                printf("onEventTriggerOff开始\n");
                trigger->funcHandler(*this, event.m_nID, trigger->m_lTriggerId, trigger->contextRef, (int)event.m_uParam, event.m_lldParam);
                printf("onEventTriggerOff结束\n");
            }
            
            if (trigger->m_eType == FSM_TRIGGER_TYPE_ONCE){
                delete trigger;
                
                m_listEventTriggers.erase(it--);
            }
        }
    }
    
    pthread_mutex_unlock(&mEventMutex);
}

// 触发器必须在dealloc中调用清除
void CFsm::CleanUpStateTriggers(long ID){
    pthread_mutex_lock(&mStateMutex);
    
    std::list<CFsm_StateTrigger *>::iterator it = m_listStateTriggers.begin();
    
    if (0 == ID){
        for (; it != m_listStateTriggers.end(); it ++){
            CFsm_StateTrigger *trigger = *it;
            
            delete trigger;
        }
        
        m_listStateTriggers.clear();
    }else{
        for (; it != m_listStateTriggers.end(); it ++){
            CFsm_StateTrigger *trigger = *it;
            
            if (trigger->m_lTriggerId == ID){
                
                m_listStateTriggers.erase(it--);
                
                delete trigger;
            }
        }
    }
    pthread_mutex_unlock(&mStateMutex);
    
    printf("CleanUpStateTriggers(ID = %ld) 清除完毕\n", ID);
}

// 触发器必须在dealloc中调用清除
void CFsm::CleanUpEventTriggers(long ID){
    pthread_mutex_lock(&mEventMutex);
    
    std::list<CFsm_EventTrigger *>::iterator it = m_listEventTriggers.begin();
    
    // 清除所有
    if (0 == ID){
        for (; it != m_listEventTriggers.end(); it ++){
            CFsm_EventTrigger *trigger = *it;
            delete trigger;
        }
        
        m_listEventTriggers.clear();
    }
    // 清除指定ID
    else{
        for (; it != m_listEventTriggers.end(); it ++){
            CFsm_EventTrigger *trigger = *it;
            
            if (trigger->m_lTriggerId == ID){
                m_listEventTriggers.erase(it --);
                
                delete trigger;
            }
        }
    }
    pthread_mutex_unlock(&mEventMutex);
    
    printf("CleanUpEventTriggers(ID = %ld) 清除完毕\n", ID);
}

bool CFsm::RegisterStateEntryAction(int nID, FSM_ACTION_FUNC entryAction){
    for (int i = 0; i < m_vStates.size(); i++){
        CFsm_State *pState = m_vStates[i];
        if (pState->m_nID == nID){
            pState->SetEntryAction(entryAction);
            return true;
        }
    }
    return false;
}

bool CFsm::RegisterStateExitAction(int nID, FSM_ACTION_FUNC exitAction){
    for (int i = 0; i < m_vStates.size(); i++){
        CFsm_State *pState = m_vStates[i];
        if (pState->m_nID == nID){
            pState->SetExitAction(exitAction);
            return true;
        }
    }
    return false;
}

void CFsm::RegisterNames(char szStateNames[][64], int nStateNum, char szEventNames[][64], int nEventNum){
    m_pszStateNames = new char *[nStateNum];
    m_pszEventNames = new char *[nEventNum];
    
    for (int i = 0; i < nStateNum; i++){
        m_pszStateNames[i] = &szStateNames[i][0];
    }
    for (int i = 0; i < nEventNum; i++){
        m_pszEventNames[i] = &szEventNames[i][0];
    }
}

const char *CFsm::GetEventName(int nID){
    if (m_pszEventNames != NULL){
        return m_pszEventNames[nID];
    }
    
    return NULL;
}

const char *CFsm::GetStateName(int nID){
    if (m_pszStateNames != NULL){
        return m_pszStateNames[nID];
    }
    
    return NULL;
}
