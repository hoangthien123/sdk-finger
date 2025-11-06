
// SgBLEDemoApp.h: 
//

#pragma once

#ifndef __AFXWIN_H__
	#error "Include 'stdafx.h' before including this file for PCH."
#endif

#include "resource.h"


// CSgBLEDemoApp:
//

class CSgBLEDemoApp : public CWinApp
{
public:
	CSgBLEDemoApp();

public:
	virtual BOOL InitInstance();

	DECLARE_MESSAGE_MAP()
};

extern CSgBLEDemoApp theApp;
