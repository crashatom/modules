//
//  FSM.h
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#ifndef __FSM_STATE_H__
#define __FSM_STATE_H__

#include <map>
#include "GWPublic.h"
#include "FsmEvent.h"

#define EVENT_DATA_MAX_SIZE     64
#define MAX_TRANSLATE_NUM       64

class CFsm;

struct translate_param{
    int nEventId;
    int nStateId;
    FSM_TRANSLATE_CHECK_FUNC fnCheck;
};
typedef translate_param TRANSLATE_LINE[MAX_TRANSLATE_NUM];
typedef translate_param TRANSLATE_TABLE[][MAX_TRANSLATE_NUM];

struct state_param{
    int nID;
    FSM_ACTION_FUNC EntryAction;
    FSM_ACTION_FUNC WorkAction;
    FSM_ACTION_FUNC ExitAction;
    translate_param *pTranslateParam;
};
typedef state_param STATE_TABLE[];

class CFsm_Segue{
public:
    int m_nEventID;
    int m_nSourceStateID;
    int m_nTargetStateID;
    
private:
    FSM_TRANSLATE_CHECK_FUNC m_fnCheck;
    
public:
    CFsm_Segue(int nEventID, int nSourceStateID, int nTargetStateID, FSM_TRANSLATE_CHECK_FUNC fnProc){
        m_fnCheck        = fnProc;
        m_nEventID       = nEventID;
        m_nSourceStateID = nSourceStateID;
        m_nTargetStateID = nTargetStateID;
    }
    
    ~CFsm_Segue(){}
    bool CheckCondition(CFsm_Event &event);
};

class CFsm_State{
public:
    CFsm_State();
    ~CFsm_State();
    
    void SetEntryAction(FSM_ACTION_FUNC fnEnteryAction);
    void SetWorkAction(FSM_ACTION_FUNC fnWorkAction);
    void SetExitAction(FSM_ACTION_FUNC fnExitAction);
    
    virtual void EntryAction(CFsm_Event &event, CFsm_Segue &segue);
    virtual void WorkAction(CFsm_Event &event, CFsm_Segue &segue);
    virtual void ExitAction(CFsm_Event &event, CFsm_Segue &segue);
    
    int AddTranslateTable(TRANSLATE_LINE TranslateLine);
    CFsm_Segue *HandleEvent(CFsm_Event &event, int &nNextStateID);
    
    CFsm_Segue *AddTranslate(translate_param &TranslateParam);
    CFsm_Segue *AddTranslate(int nEventId, int nTargetStateId, FSM_TRANSLATE_CHECK_FUNC func);
    
public:
    bool m_bIsEnd;
    int  m_nID;
    std::map<int , CFsm_Segue *> m_mTranslates;
    CFsm *m_pCFsm;
    
private:
    FSM_ACTION_FUNC m_fnEntryAction;
    FSM_ACTION_FUNC m_fnWorkAction;
    FSM_ACTION_FUNC m_fnExitAction;
};

#define FSM_BEGIN_STATE_TABLE(state_table) STATE_TABLE state_table = {
#define FSM_BEGIN_ADD_STATE(id, name, enter_func, exit_func, default_func)	{CFsm_State(id, name, enter_func, exit_func, default_func, {
#define FSM_ADD_TRANSLATE(event_id, state_id, func) {m_event_id, state_id, func},
#define FSM_END_ADD_STATE(id) {NULL, END_EVENT_ID, FSM_END_STATE_ID}}},
#define FSM_END_STATE_TABLE(state_table) {FSM_END_STATE_ID, NULL, NULL, NULL, NULL}};


#endif	//__FSM_STATE_H__
