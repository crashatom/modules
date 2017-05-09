//
//  FSM.mm
//  GoWindUI
//
//  Created by PaperMan on 15/6/29.
//  Copyright (c) 2015年 ZhiLing. All rights reserved.
//
#include "FSM.h"
#include "FsmState.h"

CFsm_State::CFsm_State(){
	m_fnEntryAction = NULL;
	m_fnExitAction = NULL;
}

CFsm_State::~CFsm_State(){
	
}

void CFsm_State::SetEntryAction(FSM_ACTION_FUNC EntryFunc){
	m_fnEntryAction = EntryFunc;
}

void CFsm_State::SetWorkAction(FSM_ACTION_FUNC fnWorkAction){
    m_fnWorkAction = fnWorkAction;
}

void CFsm_State::SetExitAction(FSM_ACTION_FUNC ExitFunc){
	m_fnExitAction = ExitFunc;
}

int CFsm_State::AddTranslateTable(TRANSLATE_LINE translate_table){
	int nExitCode = 0;
	
	if (NULL != translate_table){
		for (int i = 0; ; i++){
			if (END_EVENT_ID == translate_table[i].nEventId 
				&& FSM_STATE_END == translate_table[i].nStateId
				&& NULL == translate_table[i].fnCheck)
				break;

			CFsm_Segue *pkTranslate = NULL;
			pkTranslate = AddTranslate(translate_table[i]);
			GW_PROCESS_ERROR(pkTranslate);
		}
	}
	nExitCode = 1;
Exit0:
	
	return nExitCode;
}

CFsm_Segue *CFsm_State::AddTranslate(translate_param &param){
	CFsm_Segue *pkTranslate = NULL;

	pkTranslate = AddTranslate(param.nEventId, param.nStateId, param.fnCheck);
	GW_PROCESS_ERROR(pkTranslate);
Exit0:

	return pkTranslate;
}

CFsm_Segue *CFsm_State::AddTranslate(int nEventId, int nTargetStateId, FSM_TRANSLATE_CHECK_FUNC func){
	CFsm_Segue *pkTranslate = NULL;
    
    pkTranslate = new CFsm_Segue(nEventId, m_nID, nTargetStateId, func);
	GW_PROCESS_ERROR(pkTranslate);
    
	m_mTranslates[nEventId] = pkTranslate;
	
Exit0:
	return pkTranslate;
}

bool CFsm_Segue::CheckCondition(CFsm_Event &event){
	if (NULL != m_fnCheck)
		return m_fnCheck(event);
	return true;
}

CFsm_Segue *CFsm_State::HandleEvent(CFsm_Event &event, int &nNextStateID){
	CFsm_Segue *pCurTranslate = NULL;
	nNextStateID = FSM_STATE_END;
	std::map<int, CFsm_Segue *>::iterator it;

	if (EMPTY_EVENT_ID != event.m_nID){
		if (m_mTranslates.find(event.m_nID) != m_mTranslates.end()){
			pCurTranslate = m_mTranslates[event.m_nID];
            if (!pCurTranslate->CheckCondition(event)){
                pCurTranslate = NULL;
            }
        }else{
            DEBUG_INFO("INFO: current state: %d(%s) recvd unhandled event: %d(%s)\n", m_nID, m_pCFsm->GetStateName(m_nID), event.m_nID, m_pCFsm->GetEventName(event.m_nID));
        }
	}else{
		for (it = m_mTranslates.begin(); it != m_mTranslates.end(); it ++){
			if (it->second->CheckCondition(event)){
				pCurTranslate = it->second;
				break;
			}
		}
	}
    
	GW_PROCESS_ERROR(pCurTranslate);

	nNextStateID = pCurTranslate->m_nTargetStateID;
    DEBUG_INFO("INFO: event %d(%s) accepted by current state:%d(%s)\n", event.m_nID, m_pCFsm->GetEventName(event.m_nID), m_nID, m_pCFsm->GetStateName(m_nID));
    
	// ExitAction(event);

Exit0:

	return pCurTranslate;
}

void CFsm_State::EntryAction(CFsm_Event &event, CFsm_Segue &segue){
    if (m_fnEntryAction && m_pCFsm){
		m_fnEntryAction(*m_pCFsm, event, segue);
    }
}

void CFsm_State::WorkAction(CFsm_Event &event, CFsm_Segue &segue){
    if (m_fnWorkAction && m_pCFsm){
        m_fnWorkAction(*m_pCFsm, event, segue);
    }
}

void CFsm_State::ExitAction(CFsm_Event &event, CFsm_Segue &segue){
    if (m_fnExitAction && m_pCFsm){
		m_fnExitAction(*m_pCFsm, event, segue);
    }
}
