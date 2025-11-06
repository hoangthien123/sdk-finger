
// SgBLEDemoDlg.cpp: implementation file
//

#include "stdafx.h"
#include "SgBLEDemo.h"
#include "SgBLEDemoDlg.h"
#include "afxdialogex.h"
#include "FMSProtocol.h"
#include "sgwsqlib.h"

UINT SendThread(LPVOID lpData);

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);

protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialogEx(IDD_ABOUTBOX)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()

CSgBLEDemoDlg::CSgBLEDemoDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_TESTLIBSGBLEDEV_DIALOG, pParent)
	, m_bFullSize(FALSE)
	, m_bUseWSQ(TRUE)
	, m_bConnected(FALSE)
	, m_bIsEnumerating(FALSE)
	, m_ble(NULL)
	, m_dwTimeOut(5000) // 5000 ms
	, m_currRxPos(0)
	, m_totalRxPos(0)
	, m_pRxBufTmp(NULL)
	, m_pRxData(NULL)
	, m_pImgBuf(NULL)
	, m_ctlBitRate(0)
	, m_nWidth(U20_IMAGE_WIDTH)
	, m_nHeight(U20_IMAGE_HEIGHT)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CSgBLEDemoDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Check(pDX, IDC_CHECK_FULL_SIZE, m_bFullSize);
	DDX_Check(pDX, IDC_CHECK_USE_WSQ, m_bUseWSQ);
	DDX_Control(pDX, IDC_STATIC_IMAGE, m_ctlImgView);
	DDX_Control(pDX, IDC_COMBO_BLE_DEVICES, m_ctlBLEDevs);
	DDX_Control(pDX, IDC_LIST_LOG, m_ctlLogView);
	DDX_Radio(pDX, IDC_RADIO_R5_TO_1, (int&)m_ctlBitRate);
}

BEGIN_MESSAGE_MAP(CSgBLEDemoDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_BUTTON_ENUMERATE, &CSgBLEDemoDlg::OnBnClickedButtonEnumerate)
	ON_BN_CLICKED(IDC_BUTTON_CONNECT, &CSgBLEDemoDlg::OnBnClickedButtonConnect)
	ON_BN_CLICKED(IDC_BUTTON_DISCONNECT, &CSgBLEDemoDlg::OnBnClickedButtonDisconnect)
	ON_BN_CLICKED(IDC_BUTTON_GET_VERSION, &CSgBLEDemoDlg::OnBnClickedButtonGetVersion)
	ON_BN_CLICKED(IDC_BUTTON_GET_SERIAL_NUMBER, &CSgBLEDemoDlg::OnBnClickedButtonGetSerialNumber)
	ON_BN_CLICKED(IDC_BUTTON_IDENTIFY, &CSgBLEDemoDlg::OnBnClickedButtonIdentify)
	ON_BN_CLICKED(IDC_BUTTON_GET_IMAGE, &CSgBLEDemoDlg::OnBnClickedButtonGetImage)
	ON_BN_CLICKED(IDC_CHECK_USE_WSQ, &CSgBLEDemoDlg::OnBnClickedCheckUseWsq)
END_MESSAGE_MAP()


// CSgBLEDemoDlg message handlers

BOOL CSgBLEDemoDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != nullptr)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

	// TODO: Add extra initialization here
	m_hReceiveEndEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	m_pImgBuf = new BYTE[U20_IMAGE_WIDTH*U20_IMAGE_HEIGHT];
	m_pRxBufTmp = new BYTE[65535];

	m_DibCtl = new CDibClass(m_ctlImgView.m_hWnd);
	m_DibCtl->DibInit(m_nWidth, m_nHeight);

	return TRUE;  // return TRUE  unless you set the focus to a control
}


BOOL CSgBLEDemoDlg::DestroyWindow()
{
	if (m_ble) 
	{
		delete m_ble;
		m_ble = NULL;
	}

	if (m_pRxBufTmp) 
	{
		delete [] m_pRxBufTmp;
		m_pRxBufTmp = NULL;
	}

	if (m_pRxData) 
	{
		delete[] m_pRxData;
		m_pRxData = NULL;
	}

	if (m_pImgBuf) 
	{
		delete [] m_pImgBuf;
		m_pImgBuf = NULL;
	}

	if (m_DibCtl) 
	{
		delete m_DibCtl;
		m_DibCtl = NULL;
	}

	return CDialogEx::DestroyWindow();
}


void CSgBLEDemoDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}


void CSgBLEDemoDlg::OnPaint()
{
	CPaintDC dc(this); 

	DisplayImage();
}

HCURSOR CSgBLEDemoDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}


void CSgBLEDemoDlg::OnBnClickedButtonEnumerate()
{
	if (m_bIsEnumerating)
	{
		GetDlgItem(IDC_BUTTON_ENUMERATE)->SetWindowText(_T("Enumerate"));
		m_bIsEnumerating = FALSE;
	}
	else
	{
		GetDlgItem(IDC_BUTTON_ENUMERATE)->SetWindowText(_T("Stop"));
		if (m_ble != NULL) 
		{
			delete m_ble;
			m_ble = NULL;
		}

		m_ctlBLEDevs.ResetContent();
		m_ble = new sgble(this);
		if (m_ble == NULL)
		{
			PrintLog("Load library failed. (sgbledev.dll)");
			return;
		}

		m_bIsEnumerating = TRUE;
	}

	m_ble->Enumerate(m_bIsEnumerating);
}


void CSgBLEDemoDlg::OnBnClickedButtonConnect()
{
	if (ConnectBLE()) 
	{
		EnableWindow(TRUE);
	} 
	else 
	{
		EnableWindow(FALSE);
	}
}


void CSgBLEDemoDlg::OnBnClickedButtonDisconnect()
{
	if (m_ble)
	{
		m_ble->Disconnect();
		m_bConnected = FALSE;
	}

	EnableWindow(FALSE);
}


void CSgBLEDemoDlg::OnBnClickedButtonGetVersion()
{
	memset(&m_Pkt, 0, sizeof(BYTE)*PACKET_SIZE);
	m_Pkt.command = CMD_GET_VERSION;
	m_Pkt.checksum = MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1);

	m_dwTimeOut = 3000;
	m_currRxType = RX_BUF_TYPE_COMMAND; // Set Type to RX_BUF_TYPE_COMMAND before sending command.
	AfxBeginThread(SendThread, (LPVOID)this);
}


void CSgBLEDemoDlg::OnBnClickedButtonGetSerialNumber()
{
	memset(&m_Pkt, 0, sizeof(BYTE)*PACKET_SIZE);
	m_Pkt.command = CMD_GET_SERIAL;
	m_Pkt.checksum = MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1);

	m_dwTimeOut = 3000;
	m_currRxType = RX_BUF_TYPE_COMMAND; // Set Type to RX_BUF_TYPE_COMMAND before sending command.
	AfxBeginThread(SendThread, (LPVOID)this);
}


void CSgBLEDemoDlg::OnBnClickedButtonIdentify()
{
	memset(&m_Pkt, 0, sizeof(BYTE)*PACKET_SIZE);
	m_Pkt.command = CMD_FP_IDENTIFY;
	m_Pkt.checksum = MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1);

	m_dwTimeOut = 5000;
	m_currRxType = RX_BUF_TYPE_COMMAND;
	AfxBeginThread(SendThread, (LPVOID)this);
}


void CSgBLEDemoDlg::OnBnClickedButtonGetImage()
{
	UpdateData();
	memset(&m_Pkt, 0, sizeof(BYTE)*PACKET_SIZE);
	m_Pkt.command = CMD_GET_IMAGE;
	m_Pkt.param1 = ((m_bUseWSQ ? (0x01 << 8) : 0x00) | (m_bFullSize ? 0x01 : 0x02));
	m_Pkt.param2 = (m_bUseWSQ ? (m_ctlBitRate ? 0x0200:0x0100):0x0000);
	m_Pkt.checksum = MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1);

	m_dwTimeOut = (m_bUseWSQ ? (m_ctlBitRate ? 10000 : 20000) : 60000);
	m_currRxType = RX_BUF_TYPE_COMMAND;
	AfxBeginThread(SendThread, (LPVOID)this);
}


void CSgBLEDemoDlg::OnBnClickedCheckUseWsq()
{
	UpdateData(TRUE);
	if (m_bUseWSQ)
	{
		GetDlgItem(IDC_RADIO_R5_TO_1)->EnableWindow(TRUE);
		GetDlgItem(IDC_RADIO_R15_TO_1)->EnableWindow(TRUE);
	}
	else 
	{
		GetDlgItem(IDC_RADIO_R5_TO_1)->EnableWindow(FALSE);
		GetDlgItem(IDC_RADIO_R15_TO_1)->EnableWindow(FALSE);
	}
	UpdateData(FALSE);
}


void CSgBLEDemoDlg::EnableWindow(BOOL isConnected)
{
	if (isConnected)
	{
		GetDlgItem(IDC_BUTTON_ENUMERATE)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_CONNECT)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_DISCONNECT)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_GET_VERSION)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_GET_SERIAL_NUMBER)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_IDENTIFY)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_GET_IMAGE)->EnableWindow(TRUE);
	} 
	else 
	{
		GetDlgItem(IDC_BUTTON_ENUMERATE)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_CONNECT)->EnableWindow(TRUE);
		GetDlgItem(IDC_BUTTON_DISCONNECT)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_GET_VERSION)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_GET_SERIAL_NUMBER)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_IDENTIFY)->EnableWindow(FALSE);
		GetDlgItem(IDC_BUTTON_GET_IMAGE)->EnableWindow(FALSE);
	}
}


void CSgBLEDemoDlg::PrintLog(CStringA sLog)
{
	USES_CONVERSION;
	m_ctlLogView.AddString(CA2W(sLog));
}


BYTE CSgBLEDemoDlg::MakeCheckSum(BYTE* pbuf, DWORD num)
{
	BYTE sum = 0;
	DWORD i;

	for (i = 0; i < num; i++)
		sum += *(pbuf + i);
	return sum;
}


UINT SendThread(LPVOID lpData)
{
	CSgBLEDemoDlg* ptestlibsgbledevDlg = (CSgBLEDemoDlg*)lpData;

	if (ptestlibsgbledevDlg->m_ble && ptestlibsgbledevDlg->m_bConnected)
	{
		ptestlibsgbledevDlg->m_ble->Write((LPCSTR)&ptestlibsgbledevDlg->m_Pkt, PACKET_SIZE);
	}

	if (ptestlibsgbledevDlg->m_Pkt.command == CMD_GET_IMAGE)
		ptestlibsgbledevDlg->PrintLog("Sending command and waiting for response ...");

	DWORD ret = WaitForSingleObject(ptestlibsgbledevDlg->m_hReceiveEndEvent, ptestlibsgbledevDlg->m_dwTimeOut);
	ResetEvent(ptestlibsgbledevDlg->m_hReceiveEndEvent);
	if (ptestlibsgbledevDlg->m_ble && ptestlibsgbledevDlg->m_bConnected)
	{
		ptestlibsgbledevDlg->m_ble->ClearBuffer();
	}

	ptestlibsgbledevDlg->ParsingRxPacket(ret);

	return 0;
}


BOOL CSgBLEDemoDlg::ParsingRxPacket(DWORD eParam)
{
	CStringA strLog;
	BYTE error = ERR_NONE;
	if (m_Pkt.checksum != MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1))
		error = ERR_CHECKSUM_ERROR;
	else if (eParam == WAIT_TIMEOUT)
		error = ERR_TIMEOUT;
	else
		error = m_Pkt.error_code;

	switch (m_Pkt.command) // Add parsing to other commands
	{
		case CMD_GET_VERSION:
			if (error == ERR_NONE)
			{
				strLog.Format("Version: %x.%04x", m_Pkt.param1, m_Pkt.param2);
			} 
			else 
			{
				strLog.Format("Get Version command returned error: 0x%02x", error);
			}
			PrintLog(strLog);
			break;
		case CMD_GET_SERIAL:
			if (error == ERR_NONE)
			{
				strLog.Format("SN: %s", m_pRxData);
				USES_CONVERSION;
				GetDlgItem(IDC_EDIT_SERIAL_NUMBER)->SetWindowText(CA2W(strLog));
			}
			else 
			{
				strLog.Format("Get Serial command returned error: 0x%02x", error);
			}
			
			PrintLog(strLog);
			break;
		case CMD_FP_IDENTIFY:
			if (error == ERR_NONE)
			{
				strLog.Format("User %04X identified. Score:[ %d ]", m_Pkt.param1, m_Pkt.param2);
			}
			else if (error == ERR_IDENTIFY_FAILED)
			{
				strLog.Format("User not found.");
			}
			else
			{
				strLog.Format("FP Identify command returned error: 0x%02x", error);
			}

			PrintLog(strLog);
			break;
		case CMD_GET_IMAGE:
			if (error == ERR_NONE)
			{
				DWORD width = 0;
				DWORD height = 0;

				// send image using wsq format
				if ((m_Pkt.param1 >> 8) & 0xFF)
				{
					DWORD depth = 0;
					DWORD ppi = 0;
					DWORD lossy_flag = 1;

					BYTE* img_rec = NULL;
					DWORD err;

					err = SGWSQ_Decode(&img_rec, &width, &height, &depth, &ppi,
						&lossy_flag, m_pRxData, m_totalRxPos);

					if (err)
					{
						strLog.Format("WSQ decoding error occurred: %d ", err);
					}
					else
					{
						memcpy(m_pImgBuf, img_rec, sizeof(BYTE)*width*height);
						// If the image size has changed, reinitialize it.
						if (m_nWidth != width || m_nHeight != height)
						{
							if (m_DibCtl)
							{
								delete m_DibCtl;
								m_DibCtl = NULL;
							}

							m_nWidth = width;
							m_nHeight = height;
							m_DibCtl = new CDibClass(m_ctlImgView.m_hWnd);
							m_DibCtl->DibInit(m_nWidth, m_nHeight);
						}

						DisplayImage();
						strLog.Format("Success Get Image: %d x %d, PPI: %d", width, height, ppi);
					}
					if (img_rec)
						SGWSQ_Free(img_rec);
				} // end of wsq format
				// Send image using raw format
				else
				{
					if (U20_IMAGE_HALF_WIDTH*U20_IMAGE_HALF_HEIGHT == ((m_Pkt.h_data_size << 16) | (m_Pkt.l_data_size)))
					{
						width = U20_IMAGE_HALF_WIDTH;
						height = U20_IMAGE_HALF_HEIGHT;
					}
					else if (U20_IMAGE_WIDTH*U20_IMAGE_HEIGHT == ((m_Pkt.h_data_size << 16) | (m_Pkt.l_data_size)))
					{
						width = U20_IMAGE_WIDTH;
						height = U20_IMAGE_HEIGHT;
					}
					else
					{
						width = 0; height = 0;
					}

					if (width != 0)
					{
						memcpy(m_pImgBuf, m_pRxData, sizeof(BYTE)*width*height);
						// If the image size has changed, reinitialize it.
						if (m_nWidth != width || m_nHeight != height)
						{
							if (m_DibCtl)
							{
								delete m_DibCtl;
								m_DibCtl = NULL;
							}

							m_nWidth = width;
							m_nHeight = height;
							m_DibCtl = new CDibClass(m_ctlImgView.m_hWnd);
							m_DibCtl->DibInit(m_nWidth, m_nHeight);
						}

						DisplayImage();
						strLog.Format("Success Get Image: %d x %d", width, height);
					}
					else
					{
						strLog.Format("Get Image failed - Invalid image size ( %d )", ((m_Pkt.h_data_size << 16) | (m_Pkt.l_data_size)));
					}
				} // end of raw format
			} // end of ERR_NONE
			else 
			{
				strLog.Format("Get Image command returned error: 0x%02x", error);
			}

			PrintLog(strLog);
			break;
		default:
			break;
	}
	return TRUE;
}


BOOL CSgBLEDemoDlg::ReceivedRxPacket()
{
	if (m_currRxType == RX_BUF_TYPE_COMMAND) 
	{
		if (m_currRxPos >= PACKET_SIZE)
		{
			m_totalRxPos = 0;
			memcpy((BYTE*)&m_Pkt, m_pRxBufTmp, sizeof(BYTE)*PACKET_SIZE);
			if (m_Pkt.checksum != MakeCheckSum((BYTE*)&m_Pkt, PACKET_SIZE - 1) || m_Pkt.error_code != ERR_NONE)
			{
				PrintLog("A checksum error has occurred.");
				SetEvent(m_hReceiveEndEvent);
				m_currRxType = RX_BUF_TYPE_NONE;
			}
			else
			{
				DWORD dwExtendedSize = (m_Pkt.h_data_size << 16) | (m_Pkt.l_data_size);
				if (dwExtendedSize)
				{
					if (m_pRxData) delete[] m_pRxData;
					m_pRxData = new BYTE[dwExtendedSize + 1];
					if (m_pRxData)
					{
						memset(m_pRxData, 0, sizeof(BYTE)*(dwExtendedSize+1));
						memcpy(m_pRxData, (void*)(&m_pRxBufTmp[PACKET_SIZE]), sizeof(BYTE)*(m_currRxPos - PACKET_SIZE));
						m_totalRxPos = m_currRxPos - PACKET_SIZE;
					}

					if (m_totalRxPos >= dwExtendedSize)
					{
						// received all the extended data.
						SetEvent(m_hReceiveEndEvent);
					} 
					else 
					{
						// There are more extended data.
						m_currRxType = RX_BUF_TYPE_EXTENDED_DATA;
					}
				}
				else 
				{ 
					// There is no extension data. completed command.
					SetEvent(m_hReceiveEndEvent);
				}
			}
		}
	} 
	else if (m_currRxType == RX_BUF_TYPE_EXTENDED_DATA) 
	{
		if (m_pRxData)
		{
			memcpy(&m_pRxData[m_totalRxPos], m_pRxBufTmp, sizeof(BYTE)*m_currRxPos);
			m_totalRxPos += m_currRxPos;
		}

		if (m_totalRxPos >= (DWORD)((m_Pkt.h_data_size << 16) | m_Pkt.l_data_size))
		{
			// received all the extended data. completed command.
			SetEvent(m_hReceiveEndEvent);
		} 
		else 
		{
			;// There are more extended data.
		}
	} 
	else 
	{ 
		; // If an error occurs, set RxType to RX_BUF_TYPE_NONE and ignore it.
	}

	return TRUE;
}


void CSgBLEDemoDlg::DisplayImage()
{
	if (m_pImgBuf && m_DibCtl)
	{
		m_DibCtl->SetBits((BYTE*)m_pImgBuf);
		m_DibCtl->DrawDib();
	}
}


LRESULT CSgBLEDemoDlg::OnMyUpdate(WPARAM wpara, LPARAM lpara)
{
	UpdateData(wpara > 0 ? TRUE : FALSE);
	return 0;
}


/////////////////////////////////////////////////////////////////
// callback functions
/////////////////////////////////////////////////////////////////
void CSgBLEDemoDlg::OnBleDeviceAdded(const wchar_t* devName)
{
	m_ctlBLEDevs.AddString(CW2T(devName));
	m_ctlBLEDevs.SetCurSel(0);
}

void CSgBLEDemoDlg::OnBleEnumerationCompleted()
{
	OnBnClickedButtonEnumerate();
}

void CSgBLEDemoDlg::OnBleRx(const char *data, const int len)
{
	m_currRxPos = 0;
	memcpy(&m_pRxBufTmp[m_currRxPos], data, len); 

	m_currRxPos += len;

	PostMessage(WM_MY_UPDATE, TRUE, 0);

	ReceivedRxPacket();
}

BOOL CSgBLEDemoDlg::ConnectBLE()
{
	BOOL bConnected = FALSE;

	if (m_ble) 
	{
		// see if still enumerating
		if (m_ble->GetStatusEnumeration()) 
		{
			PrintLog("Still enumerating...");
			return bConnected;
		}

		int index = m_ctlBLEDevs.GetCurSel();
		bConnected = m_ble->Connect(index);
		m_bConnected = bConnected;

		if (bConnected)
			PrintLog("Connected.");
		else
			PrintLog("Connection failed.");
	} 
	else 
	{
		PrintLog("No Bluetooth device...");
		PrintLog("Check if enumeration has done.");
	}

	return bConnected;
}

