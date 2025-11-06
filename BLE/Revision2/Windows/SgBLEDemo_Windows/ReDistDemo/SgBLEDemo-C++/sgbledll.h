#pragma once

#include <windows.h>
#include <string>
#include <vector>

#include "ibledev.h"

class sgble
{
  public:
    sgble(LPVOID lpData);
    ~sgble();

	//sgble(LPVOID lpData);
    void Enumerate(bool start);
    bool Connect(int index);
    void Disconnect();
    bool GetStatusEnumeration() { return m_bStatusEnumeration; }
    bool Write(const char* buf, int len);
    void ClearBuffer();

  private:
    void (WINAPI *m_funcCreateBleDevice)(IBleDevice** bleDevice);
    void (WINAPI *m_funcDestroyBleDevice)(IBleDevice* bleDevice);

  private:
    IBleDevice *m_iBleDev;

    HINSTANCE m_hLib;
	const std::wstring m_dllName;
	bool m_bStatusEnumeration;
};