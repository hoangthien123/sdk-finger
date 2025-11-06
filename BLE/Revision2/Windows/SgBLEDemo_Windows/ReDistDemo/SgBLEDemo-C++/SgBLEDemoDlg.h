
// SgBLEDemoDlg.h: header file
//

#pragma once

#include "sgbledll.h"
#include "DibClass.h"

#define PACKET_SIZE 12
#define WM_MY_UPDATE WM_USER+0x100

#define U20_IMAGE_WIDTH			300
#define U20_IMAGE_HEIGHT		400
#define U20_IMAGE_HALF_WIDTH	150
#define U20_IMAGE_HALF_HEIGHT	200

// Command Packet 
typedef struct _PACKET {
	BYTE	channel;
	BYTE	command;
	WORD	param1;
	WORD	param2;
	WORD	l_data_size;
	WORD	h_data_size;
	BYTE	error_code;
	BYTE	checksum;
} PACKET;

typedef enum _RxType{
	RX_BUF_TYPE_COMMAND = 0,
	RX_BUF_TYPE_EXTENDED_DATA,
	RX_BUF_TYPE_NONE
} RxDataType;

// CSgBLEDemoDlg dialog
class CSgBLEDemoDlg : public CDialogEx
{
// Construction
public:
	CSgBLEDemoDlg(CWnd* pParent = nullptr);	// standard constructor

// Dialog Data.
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_TESTLIBSGBLEDEV_DIALOG };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support


// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	virtual BOOL OnInitDialog();
	virtual BOOL DestroyWindow();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnBnClickedButtonEnumerate();
	afx_msg void OnBnClickedButtonConnect();
	afx_msg void OnBnClickedButtonDisconnect();
	afx_msg void OnBnClickedButtonGetVersion();
	afx_msg void OnBnClickedButtonGetSerialNumber();
	afx_msg void OnBnClickedButtonIdentify();
	afx_msg void OnBnClickedButtonGetImage();
	afx_msg void OnBnClickedCheckUseWsq();

	BOOL m_bFullSize;
	BOOL m_bUseWSQ;
	CStatic m_ctlImgView;
	CComboBox m_ctlBLEDevs;
	BOOL m_bIsEnumerating;
	sgble* m_ble;
	CDibClass* m_DibCtl;
	BOOL m_bConnected;
	CListBox m_ctlLogView;
	PACKET m_Pkt;
	DWORD m_dwTimeOut; // ms
	HANDLE m_hReceiveEndEvent;
	DWORD m_currRxPos;
	DWORD m_totalRxPos;
	RxDataType m_currRxType;
	BYTE* m_pRxBufTmp;
	BYTE* m_pRxData;
	BYTE* m_pImgBuf;
	UINT m_ctlBitRate;
	UINT m_nWidth, m_nHeight;

	void EnableWindow(BOOL isConnected);
	void PrintLog(CStringA sLog);
	void DisplayImage();
	BYTE MakeCheckSum(BYTE* pbuf, DWORD num);
	BOOL ParsingRxPacket(DWORD eParam);
	BOOL ReceivedRxPacket();
	BOOL ConnectBLE(void);
	void OnBleDeviceAdded(const wchar_t* devName);
	void OnBleEnumerationCompleted();
	void OnBleRx(const char *data, const int len);
	LRESULT OnMyUpdate(WPARAM wpara, LPARAM lpara);
};
