#pragma once

#include <vector>
#include <string>

class IBleDevice
{
public:
	typedef void (WINAPI *TOnAdded)(const wchar_t* devName);		// Handler for device addition
	typedef void (WINAPI *TOnRead)(const int len, const char* buf);	// Handler for Read
	typedef void (WINAPI *TOnEnumerationCompleted)();				// Handler for enumeration completed

	virtual ~IBleDevice() {};
	virtual bool WINAPI StartDiscovery(TOnAdded onAdded, TOnEnumerationCompleted onEnumerationCompleted) = 0;
	virtual bool WINAPI StopDiscovery() = 0;
	virtual bool WINAPI Connect(int index, TOnRead onRx) = 0;
	virtual void WINAPI Disconnect() = 0;
	virtual bool WINAPI Write(int len, const char* buf) = 0;
	virtual bool WINAPI Read(int len, const char* buf) = 0;

	/// Clear Rx buffer
	virtual void WINAPI ClearBuffer() = 0;		
};

extern "C"
{
	__declspec(dllexport) void WINAPI CreateBleDevice(IBleDevice** bleDevice);
	__declspec(dllexport) void WINAPI DestroyBleDevice(IBleDevice* bleDevice);
}
