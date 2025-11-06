#include "stdafx.h"

#include <sstream>
#include <exception>
#include "sgbledll.h"

#include "SgBLEDemoDlg.h"

#include <stdio.h>
#include <atldef.h>
#include <atlstr.h>
using namespace ATL;

CSgBLEDemoDlg* g_testlibsgbledev = NULL;

/*
 * callback functions defined
 */
void WINAPI OnBleDeviceAdded(const wchar_t* devName)
{
	if (g_testlibsgbledev)
		g_testlibsgbledev->OnBleDeviceAdded(devName);
}

void WINAPI OnBleEmumerationCompleted()
{
	if (g_testlibsgbledev)
		g_testlibsgbledev->OnBleEnumerationCompleted();
}

void WINAPI OnBleRx(const int len,  const char *buf)
{
	if (g_testlibsgbledev)
		g_testlibsgbledev->OnBleRx(buf, len);
}

/*
 * implementations of class sgble
 */
/*
sgble::sgble() : m_iBleDev(NULL), m_dllName("sgbledev.dll"),
                 m_funcCreateBleDevice(NULL), m_funcDestroyBleDevice(NULL),
                 m_bStatusEnumeration(false)
{
    std::stringstream msg;
    m_hLib = LoadLibrary(m_dllName.c_str());

    if (m_hLib)
    {
        m_funcCreateBleDevice = (void(WINAPI *)(IBleDevice **))GetProcAddress(m_hLib, "CreateBleDevice");
        m_funcDestroyBleDevice = (void(WINAPI *)(IBleDevice *))GetProcAddress(m_hLib, "DestroyBleDevice");

        if (m_funcCreateBleDevice)
        {
            m_funcCreateBleDevice(&m_iBleDev);
        }

        if (m_iBleDev == NULL)
        {
            msg << "Error: Cannot create BluetoothLE device";
            throw msg.str();
        }
    }
    else
    {
        DWORD lastError = GetLastError();
        msg << "Error: Cannot load " << m_dllName << " (" << lastError << ")";
        throw msg.str();
    }
}
//*/
sgble::sgble(LPVOID lpData) : m_iBleDev(NULL), m_dllName(_T("sgbledev.dll")), 
m_funcCreateBleDevice(NULL), m_funcDestroyBleDevice(NULL),
m_bStatusEnumeration(false)
{
	std::stringstream msg;
	m_hLib = LoadLibrary((LPWSTR)m_dllName.c_str());

	if (m_hLib)
	{
		m_funcCreateBleDevice = (void(WINAPI *)(IBleDevice **))GetProcAddress(m_hLib, "CreateBleDevice");
		m_funcDestroyBleDevice = (void(WINAPI *)(IBleDevice *))GetProcAddress(m_hLib, "DestroyBleDevice");

		if (m_funcCreateBleDevice)
		{
			m_funcCreateBleDevice(&m_iBleDev);
		}

		if (m_iBleDev == NULL)
		{
			msg << "Error: Cannot create BluetoothLE device";
			//throw msg.str();
		}

		g_testlibsgbledev = (CSgBLEDemoDlg*)lpData;
	}
	else
	{
		DWORD lastError = GetLastError();
		msg << "Error: Cannot load " << m_dllName.c_str() << " (" << lastError << ")";
		//throw msg.str();s
	}
}

sgble::~sgble()
{
    if (m_iBleDev)
    {
        if (m_funcDestroyBleDevice)
        {
            m_funcDestroyBleDevice(m_iBleDev);
        }
        m_iBleDev = NULL;
    }

    if (m_hLib)
    {
        FreeLibrary(m_hLib);
    }

	g_testlibsgbledev = NULL;
}

void sgble::Enumerate(bool start)
{
    if (m_iBleDev == NULL)
        return;

    if (start)
    {
        m_iBleDev->StartDiscovery(OnBleDeviceAdded, OnBleEmumerationCompleted);
        m_bStatusEnumeration = true;
    }
    else 
    {
        m_iBleDev->StopDiscovery();
        m_bStatusEnumeration = false;
    }
}

bool sgble::Connect(int index)
{
    bool connected = false;
    if (m_iBleDev) 
    {
        connected = m_iBleDev->Connect(index, OnBleRx);
    }
    return connected;
}

void sgble::Disconnect()
{
    if (m_iBleDev)
    {
        m_iBleDev->Disconnect();
    }
}

bool sgble::Write(const char* buf, int len)
{
    bool res = false;
    if (m_iBleDev) {
        res = m_iBleDev->Write(len, buf);
    }
    return res;
}

void sgble::ClearBuffer()
{
    if (m_iBleDev) {
        m_iBleDev->ClearBuffer();
    }
}