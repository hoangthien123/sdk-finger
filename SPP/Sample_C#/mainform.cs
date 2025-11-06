using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.Text;
using System.Threading;
using System.Globalization;

namespace un20_fms
{
	/// <summary>
	/// This is the main application for UN20 Fingerprint Management System (FMS) sample application that performs basic functions such as:
    ///     Image capture.
    ///     User registration
    ///     User identification
    ///     User deletion
    ///     Basic 
	/// </summary>
    /// 


   public class MainForm : System.Windows.Forms.Form
   {
      /// <summary>
      /// Required designer variable.
      /// </summary>
      /// 
      private Packet m_Packet;
      private Packet m_Ack;
      private UInt32 m_ExtendedDataSize;
      private Byte[] m_ExtendedData;
      private bool m_AckFlag;
      private byte m_ImageViewSize = 1;

      private Int32 m_ImageWidth;
      private Int32 m_ImageHeight;
      private Byte[] m_RegMin1;
      private Byte[] m_RegMin2;
      private Byte[] m_VrfMin;
      private const Int32 MIN_IMG_QLTY = 80;
      private IContainer components;
      private System.Windows.Forms.TabControl tabControl1;
      private System.Windows.Forms.TabPage tabPage2;
      private System.Windows.Forms.Label label1;
      private System.Windows.Forms.ComboBox comboBoxComPort;
      private System.Windows.Forms.Button OpenDeviceBtn;
      private System.IO.Ports.SerialPort serialPort1;
      private Label label19;
      private ComboBox comboBoxBaudRate;
      private RichTextBox richTextBoxOutput;
      private Button buttonCMD_GET_VERSION;
      private Button buttonCMD_GET_IMAGE;
      private GroupBox groupBox3;
      private PictureBox pictureBox1;
      private RadioButton radioButtonFullSizeImage;
      private RadioButton radioButtonHalfSizeImage;
      private Button buttonCMD_DEVICE_TEST;
      private TabPage tabPage4;
      private TextBox textBoxTestCommand;
      private Label label3;
      private Button buttonSendCommand;
      private TextBox textBoxTestParam2;
      private Label label5;
      private TextBox textBoxTestParam1;
      private Label label4;
      private Button buttonCMD_FP_IDENTIFY;
      private Button buttonCMD_FP_VERIFY;
      private Button buttonCMD_FP_DELETE;
      private Label label6;
      private TextBox textBoxUserID;
      private Button buttonCMD_FP_REGISTER_START;
      private System.Windows.Forms.Label StatusBar;
      private const Int32 UN20_IMAGE_WIDTH  = 300;
      private Label label2;
      private const Int32 UN20_IMAGE_HEIGHT = 400;

      //SecuGen FMS Protocol Commands
      private Byte CMD_GET_VERSION = 0x05;
      private Byte CMD_DEVICE_TEST = 0x10;
      private Byte CMD_GET_IMAGE = 0x43;
      private Byte CMD_FP_REGISTER_START = 0x50;
      private Byte CMD_FP_REGISTER_END = 0x51;
      private Byte CMD_FP_DELETE = 0x54;
      private Byte CMD_FP_VERIFY = 0x55;
      private Byte CMD_FP_IDENTIFY = 0x56;


      public MainForm()
      {
         //
         // Required for Windows Form Designer support
         //
         InitializeComponent();

         //
         // TODO: Add any constructor code after InitializeComponent call
         //
         //m_FPM = 0;
         // Get Device Name
      }

      /// <summary>
      /// Clean up any resources being used.
      /// </summary>
      protected override void Dispose( bool disposing )
      {
         if( disposing )
         {
            if (components != null) 
            {
               components.Dispose();
            }
         }
         base.Dispose( disposing );
      }

      #region Windows Form Designer generated code
      /// <summary>
      /// Required method for Designer support - do not modify
      /// the contents of this method with the code editor.
      /// </summary>
      private void InitializeComponent()
      {
            this.components = new System.ComponentModel.Container();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.buttonCMD_FP_IDENTIFY = new System.Windows.Forms.Button();
            this.radioButtonHalfSizeImage = new System.Windows.Forms.RadioButton();
            this.buttonCMD_FP_VERIFY = new System.Windows.Forms.Button();
            this.buttonCMD_FP_DELETE = new System.Windows.Forms.Button();
            this.radioButtonFullSizeImage = new System.Windows.Forms.RadioButton();
            this.label6 = new System.Windows.Forms.Label();
            this.buttonCMD_GET_IMAGE = new System.Windows.Forms.Button();
            this.textBoxUserID = new System.Windows.Forms.TextBox();
            this.buttonCMD_FP_REGISTER_START = new System.Windows.Forms.Button();
            this.buttonCMD_DEVICE_TEST = new System.Windows.Forms.Button();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.buttonCMD_GET_VERSION = new System.Windows.Forms.Button();
            this.tabPage4 = new System.Windows.Forms.TabPage();
            this.buttonSendCommand = new System.Windows.Forms.Button();
            this.textBoxTestParam2 = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.textBoxTestParam1 = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.textBoxTestCommand = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.OpenDeviceBtn = new System.Windows.Forms.Button();
            this.comboBoxComPort = new System.Windows.Forms.ComboBox();
            this.label1 = new System.Windows.Forms.Label();
            this.StatusBar = new System.Windows.Forms.Label();
            this.serialPort1 = new System.IO.Ports.SerialPort(this.components);
            this.label19 = new System.Windows.Forms.Label();
            this.comboBoxBaudRate = new System.Windows.Forms.ComboBox();
            this.richTextBoxOutput = new System.Windows.Forms.RichTextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.tabControl1.SuspendLayout();
            this.tabPage2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.tabPage4.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tabPage2);
            this.tabControl1.Controls.Add(this.tabPage4);
            this.tabControl1.Location = new System.Drawing.Point(0, 40);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(576, 462);
            this.tabControl1.TabIndex = 0;
            // 
            // tabPage2
            // 
            this.tabPage2.Controls.Add(this.buttonCMD_FP_IDENTIFY);
            this.tabPage2.Controls.Add(this.radioButtonHalfSizeImage);
            this.tabPage2.Controls.Add(this.buttonCMD_FP_VERIFY);
            this.tabPage2.Controls.Add(this.buttonCMD_FP_DELETE);
            this.tabPage2.Controls.Add(this.radioButtonFullSizeImage);
            this.tabPage2.Controls.Add(this.label6);
            this.tabPage2.Controls.Add(this.buttonCMD_GET_IMAGE);
            this.tabPage2.Controls.Add(this.textBoxUserID);
            this.tabPage2.Controls.Add(this.buttonCMD_FP_REGISTER_START);
            this.tabPage2.Controls.Add(this.buttonCMD_DEVICE_TEST);
            this.tabPage2.Controls.Add(this.groupBox3);
            this.tabPage2.Controls.Add(this.buttonCMD_GET_VERSION);
            this.tabPage2.Location = new System.Drawing.Point(4, 22);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Size = new System.Drawing.Size(568, 436);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "General";
            this.tabPage2.UseVisualStyleBackColor = true;
            // 
            // buttonCMD_FP_IDENTIFY
            // 
            this.buttonCMD_FP_IDENTIFY.Location = new System.Drawing.Point(340, 281);
            this.buttonCMD_FP_IDENTIFY.Name = "buttonCMD_FP_IDENTIFY";
            this.buttonCMD_FP_IDENTIFY.Size = new System.Drawing.Size(195, 34);
            this.buttonCMD_FP_IDENTIFY.TabIndex = 25;
            this.buttonCMD_FP_IDENTIFY.Text = "CMD_FP_IDENTIFY (0x56)";
            this.buttonCMD_FP_IDENTIFY.UseVisualStyleBackColor = true;
            this.buttonCMD_FP_IDENTIFY.Click += new System.EventHandler(this.buttonCMD_FP_IDENTIFY_Click_1);
            // 
            // radioButtonHalfSizeImage
            // 
            this.radioButtonHalfSizeImage.AutoSize = true;
            this.radioButtonHalfSizeImage.Location = new System.Drawing.Point(458, 376);
            this.radioButtonHalfSizeImage.Name = "radioButtonHalfSizeImage";
            this.radioButtonHalfSizeImage.Size = new System.Drawing.Size(83, 17);
            this.radioButtonHalfSizeImage.TabIndex = 18;
            this.radioButtonHalfSizeImage.TabStop = true;
            this.radioButtonHalfSizeImage.Text = "Quarter Size";
            this.radioButtonHalfSizeImage.UseVisualStyleBackColor = true;
            // 
            // buttonCMD_FP_VERIFY
            // 
            this.buttonCMD_FP_VERIFY.Location = new System.Drawing.Point(340, 241);
            this.buttonCMD_FP_VERIFY.Name = "buttonCMD_FP_VERIFY";
            this.buttonCMD_FP_VERIFY.Size = new System.Drawing.Size(195, 34);
            this.buttonCMD_FP_VERIFY.TabIndex = 24;
            this.buttonCMD_FP_VERIFY.Text = "CMD_FP_VERIFY (0x55)";
            this.buttonCMD_FP_VERIFY.UseVisualStyleBackColor = true;
            this.buttonCMD_FP_VERIFY.Click += new System.EventHandler(this.buttonCMD_FP_VERIFY_Click_1);
            // 
            // buttonCMD_FP_DELETE
            // 
            this.buttonCMD_FP_DELETE.Location = new System.Drawing.Point(340, 205);
            this.buttonCMD_FP_DELETE.Name = "buttonCMD_FP_DELETE";
            this.buttonCMD_FP_DELETE.Size = new System.Drawing.Size(195, 30);
            this.buttonCMD_FP_DELETE.TabIndex = 23;
            this.buttonCMD_FP_DELETE.Text = "CMD_FP_DELETE (0x54)";
            this.buttonCMD_FP_DELETE.UseVisualStyleBackColor = true;
            this.buttonCMD_FP_DELETE.Click += new System.EventHandler(this.buttonCMD_FP_DELETE_Click_1);
            // 
            // radioButtonFullSizeImage
            // 
            this.radioButtonFullSizeImage.AutoSize = true;
            this.radioButtonFullSizeImage.Location = new System.Drawing.Point(458, 353);
            this.radioButtonFullSizeImage.Name = "radioButtonFullSizeImage";
            this.radioButtonFullSizeImage.Size = new System.Drawing.Size(64, 17);
            this.radioButtonFullSizeImage.TabIndex = 17;
            this.radioButtonFullSizeImage.TabStop = true;
            this.radioButtonFullSizeImage.Text = "Full Size";
            this.radioButtonFullSizeImage.UseVisualStyleBackColor = true;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(342, 143);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(90, 13);
            this.label6.TabIndex = 22;
            this.label6.Text = "User ID (Decimal)";
            // 
            // buttonCMD_GET_IMAGE
            // 
            this.buttonCMD_GET_IMAGE.Location = new System.Drawing.Point(340, 353);
            this.buttonCMD_GET_IMAGE.Name = "buttonCMD_GET_IMAGE";
            this.buttonCMD_GET_IMAGE.Size = new System.Drawing.Size(112, 53);
            this.buttonCMD_GET_IMAGE.TabIndex = 16;
            this.buttonCMD_GET_IMAGE.Text = "CMD_GET_IMAGE (0x43)";
            this.buttonCMD_GET_IMAGE.UseVisualStyleBackColor = true;
            this.buttonCMD_GET_IMAGE.Click += new System.EventHandler(this.buttonCMD_GET_IMAGE_Click);
            // 
            // textBoxUserID
            // 
            this.textBoxUserID.Location = new System.Drawing.Point(438, 140);
            this.textBoxUserID.Name = "textBoxUserID";
            this.textBoxUserID.Size = new System.Drawing.Size(77, 20);
            this.textBoxUserID.TabIndex = 21;
            this.textBoxUserID.Text = "0000";
            // 
            // buttonCMD_FP_REGISTER_START
            // 
            this.buttonCMD_FP_REGISTER_START.Location = new System.Drawing.Point(340, 166);
            this.buttonCMD_FP_REGISTER_START.Name = "buttonCMD_FP_REGISTER_START";
            this.buttonCMD_FP_REGISTER_START.Size = new System.Drawing.Size(195, 33);
            this.buttonCMD_FP_REGISTER_START.TabIndex = 20;
            this.buttonCMD_FP_REGISTER_START.Text = "CMD_FP_REGISTER_START (0x50)";
            this.buttonCMD_FP_REGISTER_START.UseVisualStyleBackColor = true;
            this.buttonCMD_FP_REGISTER_START.Click += new System.EventHandler(this.buttonCMD_FP_REGISTER_START_Click_1);
            // 
            // buttonCMD_DEVICE_TEST
            // 
            this.buttonCMD_DEVICE_TEST.Location = new System.Drawing.Point(342, 43);
            this.buttonCMD_DEVICE_TEST.Name = "buttonCMD_DEVICE_TEST";
            this.buttonCMD_DEVICE_TEST.Size = new System.Drawing.Size(193, 25);
            this.buttonCMD_DEVICE_TEST.TabIndex = 19;
            this.buttonCMD_DEVICE_TEST.Text = "CMD_DEVICE_TEST (0x10)";
            this.buttonCMD_DEVICE_TEST.UseVisualStyleBackColor = true;
            this.buttonCMD_DEVICE_TEST.Click += new System.EventHandler(this.buttonCMD_DEVICE_TEST_Click);
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.pictureBox1);
            this.groupBox3.Location = new System.Drawing.Point(7, 3);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(315, 430);
            this.groupBox3.TabIndex = 18;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Get Image";
            // 
            // pictureBox1
            // 
            this.pictureBox1.BackColor = System.Drawing.SystemColors.ControlLight;
            this.pictureBox1.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.pictureBox1.Location = new System.Drawing.Point(7, 19);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(300, 400);
            this.pictureBox1.TabIndex = 5;
            this.pictureBox1.TabStop = false;
            // 
            // buttonCMD_GET_VERSION
            // 
            this.buttonCMD_GET_VERSION.Location = new System.Drawing.Point(342, 12);
            this.buttonCMD_GET_VERSION.Name = "buttonCMD_GET_VERSION";
            this.buttonCMD_GET_VERSION.Size = new System.Drawing.Size(193, 25);
            this.buttonCMD_GET_VERSION.TabIndex = 13;
            this.buttonCMD_GET_VERSION.Text = "CMD_GET_VERSION (0x05)";
            this.buttonCMD_GET_VERSION.UseVisualStyleBackColor = true;
            this.buttonCMD_GET_VERSION.Click += new System.EventHandler(this.buttonCMD_GET_VERSION_Click);
            // 
            // tabPage4
            // 
            this.tabPage4.Controls.Add(this.buttonSendCommand);
            this.tabPage4.Controls.Add(this.textBoxTestParam2);
            this.tabPage4.Controls.Add(this.label5);
            this.tabPage4.Controls.Add(this.textBoxTestParam1);
            this.tabPage4.Controls.Add(this.label4);
            this.tabPage4.Controls.Add(this.textBoxTestCommand);
            this.tabPage4.Controls.Add(this.label3);
            this.tabPage4.Location = new System.Drawing.Point(4, 22);
            this.tabPage4.Name = "tabPage4";
            this.tabPage4.Size = new System.Drawing.Size(568, 436);
            this.tabPage4.TabIndex = 3;
            this.tabPage4.Text = "Simple Command";
            this.tabPage4.UseVisualStyleBackColor = true;
            // 
            // buttonSendCommand
            // 
            this.buttonSendCommand.Location = new System.Drawing.Point(59, 119);
            this.buttonSendCommand.Name = "buttonSendCommand";
            this.buttonSendCommand.Size = new System.Drawing.Size(162, 36);
            this.buttonSendCommand.TabIndex = 6;
            this.buttonSendCommand.Text = "Send Command";
            this.buttonSendCommand.UseVisualStyleBackColor = true;
            this.buttonSendCommand.Click += new System.EventHandler(this.buttonSendCommand_Click);
            // 
            // textBoxTestParam2
            // 
            this.textBoxTestParam2.Location = new System.Drawing.Point(88, 82);
            this.textBoxTestParam2.Name = "textBoxTestParam2";
            this.textBoxTestParam2.Size = new System.Drawing.Size(151, 20);
            this.textBoxTestParam2.TabIndex = 5;
            this.textBoxTestParam2.Text = "00";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(28, 85);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(43, 13);
            this.label5.TabIndex = 4;
            this.label5.Text = "Param2";
            // 
            // textBoxTestParam1
            // 
            this.textBoxTestParam1.Location = new System.Drawing.Point(88, 56);
            this.textBoxTestParam1.Name = "textBoxTestParam1";
            this.textBoxTestParam1.Size = new System.Drawing.Size(151, 20);
            this.textBoxTestParam1.TabIndex = 3;
            this.textBoxTestParam1.Text = "00";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(28, 59);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(43, 13);
            this.label4.TabIndex = 2;
            this.label4.Text = "Param1";
            // 
            // textBoxTestCommand
            // 
            this.textBoxTestCommand.Location = new System.Drawing.Point(88, 30);
            this.textBoxTestCommand.Name = "textBoxTestCommand";
            this.textBoxTestCommand.Size = new System.Drawing.Size(151, 20);
            this.textBoxTestCommand.TabIndex = 1;
            this.textBoxTestCommand.Text = "05";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(28, 33);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(54, 13);
            this.label3.TabIndex = 0;
            this.label3.Text = "Command";
            // 
            // OpenDeviceBtn
            // 
            this.OpenDeviceBtn.BackColor = System.Drawing.SystemColors.ActiveBorder;
            this.OpenDeviceBtn.Location = new System.Drawing.Point(344, 10);
            this.OpenDeviceBtn.Name = "OpenDeviceBtn";
            this.OpenDeviceBtn.Size = new System.Drawing.Size(112, 24);
            this.OpenDeviceBtn.TabIndex = 3;
            this.OpenDeviceBtn.Text = "Connect";
            this.OpenDeviceBtn.UseVisualStyleBackColor = false;
            this.OpenDeviceBtn.Click += new System.EventHandler(this.OpenDeviceBtn_Click);
            // 
            // comboBoxComPort
            // 
            this.comboBoxComPort.Items.AddRange(new object[] {
            "COM1",
            "COM2",
            "COM3",
            "COM4",
            "COM5",
            "COM6",
            "COM7",
            "COM8",
            "COM9",
            "COM10",
            "COM11",
            "COM12",
            "COM13",
            "COM14",
            "COM15",
            "COM16"});
            this.comboBoxComPort.Location = new System.Drawing.Point(62, 10);
            this.comboBoxComPort.Name = "comboBoxComPort";
            this.comboBoxComPort.Size = new System.Drawing.Size(95, 21);
            this.comboBoxComPort.TabIndex = 1;
            this.comboBoxComPort.Text = "COM1";
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(5, 13);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(51, 24);
            this.label1.TabIndex = 3;
            this.label1.Text = "Com Port";
            // 
            // StatusBar
            // 
            this.StatusBar.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.StatusBar.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.StatusBar.ForeColor = System.Drawing.SystemColors.Highlight;
            this.StatusBar.Location = new System.Drawing.Point(0, 511);
            this.StatusBar.Name = "StatusBar";
            this.StatusBar.Size = new System.Drawing.Size(894, 24);
            this.StatusBar.TabIndex = 7;
            // 
            // serialPort1
            // 
            this.serialPort1.ReadBufferSize = 130000;
            this.serialPort1.DataReceived += new System.IO.Ports.SerialDataReceivedEventHandler(this.serialPort1_DataReceived);
            // 
            // label19
            // 
            this.label19.Location = new System.Drawing.Point(164, 13);
            this.label19.Name = "label19";
            this.label19.Size = new System.Drawing.Size(58, 24);
            this.label19.TabIndex = 9;
            this.label19.Text = "BaudRate";
            // 
            // comboBoxBaudRate
            // 
            this.comboBoxBaudRate.Items.AddRange(new object[] {
            "115200"});
            this.comboBoxBaudRate.Location = new System.Drawing.Point(228, 10);
            this.comboBoxBaudRate.Name = "comboBoxBaudRate";
            this.comboBoxBaudRate.Size = new System.Drawing.Size(95, 21);
            this.comboBoxBaudRate.TabIndex = 8;
            this.comboBoxBaudRate.Text = "115200";
            // 
            // richTextBoxOutput
            // 
            this.richTextBoxOutput.Font = new System.Drawing.Font("Courier New", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.richTextBoxOutput.Location = new System.Drawing.Point(582, 62);
            this.richTextBoxOutput.Name = "richTextBoxOutput";
            this.richTextBoxOutput.Size = new System.Drawing.Size(303, 440);
            this.richTextBoxOutput.TabIndex = 10;
            this.richTextBoxOutput.Text = "";
            this.richTextBoxOutput.TextChanged += new System.EventHandler(this.richTextBoxOutput_TextChanged);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(494, 16);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(226, 13);
            this.label2.TabIndex = 11;
            this.label2.Text = "NOTE: Unity Bluetooth baud rate is 15200 bps";
            // 
            // MainForm
            // 
            this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
            this.ClientSize = new System.Drawing.Size(894, 535);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.richTextBoxOutput);
            this.Controls.Add(this.label19);
            this.Controls.Add(this.comboBoxBaudRate);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.comboBoxComPort);
            this.Controls.Add(this.tabControl1);
            this.Controls.Add(this.StatusBar);
            this.Controls.Add(this.OpenDeviceBtn);
            this.Name = "MainForm";
            this.Text = "SecuGen Unity Bluetooth Fingerprint Management System C# Sample";
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.tabControl1.ResumeLayout(false);
            this.tabPage2.ResumeLayout(false);
            this.tabPage2.PerformLayout();
            this.groupBox3.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.tabPage4.ResumeLayout(false);
            this.tabPage4.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

      }
      #endregion

      /// <summary>
      /// The main entry point for the application.
      /// </summary>
      [STAThread]
      static void Main() 
      {
         Application.Run(new MainForm());
      }

      private void MainForm_Load(object sender, System.EventArgs e)
      {
         comboBoxComPort.SelectedIndex = 0;//COM1;

         EnableButtons(false);
         m_Packet = new Packet();
         m_Ack = new Packet();
         m_ExtendedData = new Byte[UN20_IMAGE_WIDTH * UN20_IMAGE_HEIGHT];
         StatusBar.Text = "Click Init Button";
         m_RegMin1 = new Byte[400];
         m_RegMin2 = new Byte[400];
         m_VrfMin = new Byte[400];
         this.radioButtonHalfSizeImage.Select();
         m_ImageWidth = UN20_IMAGE_WIDTH;
         m_ImageHeight = UN20_IMAGE_HEIGHT;
     }
      
      private void OpenDeviceBtn_Click(object sender, System.EventArgs e)
      {
         bool ret;

          if(this.serialPort1.IsOpen)
              this.serialPort1.Close();
          serialPort1.PortName = comboBoxComPort.Text;
          serialPort1.BaudRate = Convert.ToInt32(comboBoxBaudRate.Text);
          serialPort1.Parity = System.IO.Ports.Parity.None;
          serialPort1.DataBits = 8;
          serialPort1.StopBits = System.IO.Ports.StopBits.One;
          serialPort1.Handshake = System.IO.Ports.Handshake.None;
          serialPort1.ReadBufferSize = 130000;
          try {
            serialPort1.Open();

            ////////////////////////////////////////////////////////
            //  Verify connectivity
            //  Send CMD_DEVICE_TEST and confirm error 0x00 received.
            ret = SendCommandReceiveAck(CMD_DEVICE_TEST, 0x00, 0x00, 0, 30000);
            Thread.Sleep(200);   //Pause briefly to wait for response
            if ((ret) && (this.m_Ack.ErrorCode == 0x00))
            {
                this.richTextBoxOutput.AppendText("Connection successful - " + comboBoxComPort.Text + ":" + comboBoxBaudRate.Text + "\n");
                StatusBar.Text = "Initialization Success";
                EnableButtons(true);
            }
            else
                this.richTextBoxOutput.AppendText("ERROR: Port opened but UN20 FMS not found.\n");

          }
          catch( Exception ioexception)
          {
              this.richTextBoxOutput.AppendText("ERROR: Connection failed - " + comboBoxComPort.Text + ":" + comboBoxBaudRate.Text + "\n");
              StatusBar.Text = "ERROR" + ioexception.ToString();
          }
      }

      private void EnableButtons(bool enable)
      {
         this.buttonCMD_GET_VERSION.Enabled = enable;
         this.buttonCMD_DEVICE_TEST.Enabled = enable;
         this.buttonCMD_GET_IMAGE.Enabled = enable;
         this.buttonCMD_FP_IDENTIFY.Enabled = enable;
         this.buttonCMD_FP_REGISTER_START.Enabled = enable;
         this.buttonCMD_FP_DELETE.Enabled = enable;
         this.buttonCMD_FP_VERIFY.Enabled = enable;
         this.buttonSendCommand.Enabled = enable;   
      }

      private bool SendCommandReceiveAck(Byte command, UInt16 param1, UInt16 param2, UInt32 extradata_size, Int32 timeout)
      {
        Int32 cnt;
        
        this.m_ExtendedDataSize = extradata_size;
        this.m_Packet.reset();
        this.m_Packet.Command = command;
        this.m_Packet.Param1 = param1;
        this.m_Packet.Param2 = param2;
        this.m_Packet.LWExtraData = Convert.ToUInt16(this.m_ExtendedDataSize & 0xFFFF);
        this.m_Packet.HWExtraData = Convert.ToUInt16(this.m_ExtendedDataSize >> 16 & 0xFFFF);

        m_AckFlag = true;
        
        SendPacket();
        
        cnt = 0;
        timeout = timeout * 1000;

        while (m_AckFlag && (cnt < timeout))
        {
            Application.DoEvents();
            cnt = cnt + 1;
        }
        
        if (cnt == timeout)
            return false;
        else
            return true;    
        
     }

     private void SendPacket()
     {

        Int16 i, checksum;
        Byte[] buff = new Byte[12];

        this.m_Packet.Channel = 0;
        this.m_Packet.ErrorCode = 0;
        this.m_Packet.CheckSum = 0;
    
        buff[0] = this.m_Packet.Channel;
        buff[1] = this.m_Packet.Command;
        buff[2] = Convert.ToByte(this.m_Packet.Param1 & 0xFF);
        buff[3] = Convert.ToByte(this.m_Packet.Param1 >> 8 & 0xFF);
        buff[4] = Convert.ToByte(this.m_Packet.Param2 & 0xFF);
        buff[5] = Convert.ToByte(this.m_Packet.Param2 >> 8 & 0xFF);
        buff[6] = Convert.ToByte(this.m_Packet.LWExtraData >> 8 & 0xFF);
        buff[7] = Convert.ToByte(this.m_Packet.LWExtraData & 0xFF);
        buff[6] = Convert.ToByte(this.m_Packet.HWExtraData >> 8 & 0xFF);
        buff[9] = Convert.ToByte(this.m_Packet.HWExtraData & 0xFF);
        buff[10] = Convert.ToByte(this.m_Packet.ErrorCode);
        
        for (i=0; i<=10; ++i)
        {
            checksum = Convert.ToInt16(Convert.ToInt16(this.m_Packet.CheckSum) + Convert.ToInt16(buff[i]));
             this.m_Packet.CheckSum = Convert.ToByte(checksum & 0xFF);
             //this.m_Packet.CheckSum = Convert.ToByte(this.m_Packet.CheckSum + buff[i]);
        }

        buff[11] = this.m_Packet.CheckSum;

        this.serialPort1.Write(buff,0,12);
    }

    #region UN20 FMS  Application Event Handlers

    private void serialPort1_DataReceived(object sender, System.IO.Ports.SerialDataReceivedEventArgs e)
    {
        byte[] packet = new byte[12];
        byte[] shortBuff = new byte[2];
        int temp;
        string str = string.Empty;
        try
        {
            temp = serialPort1.Read(packet, 0, 12);
        }
        catch (Exception)
        {
            //TODO Handle exception
        }

        m_AckFlag = false;
        this.m_Ack.reset();
        this.m_Ack.Channel = packet[0];
        this.m_Ack.Command = packet[1];
        //this.m_Ack.Param1
        shortBuff[0] = packet[2];
        shortBuff[1] = packet[3];
        this.m_Ack.Param1 = BitConverter.ToUInt16(shortBuff, 0);
        //this.m_Ack.Param2
        shortBuff[0] = packet[4];
        shortBuff[1] = packet[5];
        this.m_Ack.Param2 = BitConverter.ToUInt16(shortBuff, 0);
        //this.m_Ack.LWExtraData
        shortBuff[0] = packet[6];
        shortBuff[1] = packet[7];
        this.m_Ack.LWExtraData = BitConverter.ToUInt16(shortBuff, 0);
        //this.m_Ack.HWExtraData
        shortBuff[0] = packet[8];
        shortBuff[1] = packet[9];
        this.m_Ack.HWExtraData = BitConverter.ToUInt16(shortBuff, 0);
        this.m_Ack.ErrorCode = packet[10];
        this.m_Ack.CheckSum = packet[11];
        this.m_ExtendedDataSize = Convert.ToUInt32(Convert.ToUInt32(this.m_Ack.HWExtraData) << 16 | Convert.ToUInt32(this.m_Ack.LWExtraData));

        if (this.m_Ack.Command == CMD_GET_IMAGE)
        {
            unsafe
            {
                int totalLen = 0;
                int Width = 0, Height = 0, Padding = 0;
                int dataLen = (int)(packet[6] | (packet[7] << 8) | (packet[8] << 16) | (packet[9] << 24));
                byte[] buffer = new byte[dataLen];
                if (packet[2] == 0x01)
                {
                    Width = 300;
                    Height = 400;
                }
                else
                {
                    Width = 150;
                    Height = 200;
                }
                Padding = (((8 * Width) + 31) / 32 * 4) - Width; //In Bitmap, width must be multiple of 4

                //Read image data
                while (totalLen < dataLen)
                {
                    totalLen += serialPort1.Read(buffer, totalLen, (dataLen - totalLen));
                }

                Bitmap BitmapImage = new Bitmap(Width, Height, PixelFormat.Format8bppIndexed);
                BitmapData BitmapImageData = BitmapImage.LockBits(new Rectangle(0, 0, Width, Height)
                                                                , ImageLockMode.WriteOnly
                                                                , PixelFormat.Format8bppIndexed);
                
                byte* Pointer = (byte*)BitmapImageData.Scan0.ToPointer();

                for (int i = 0; i < totalLen; i++, Pointer++)
                {
                     *Pointer = buffer[i];
                     if ((i+1) % Width == 0)
                         Pointer += Padding;
                }

                BitmapImage.UnlockBits(BitmapImageData);
                ColorPalette GrayscalePalette = BitmapImage.Palette;

                for (int i=0; i<256; i++)
                    GrayscalePalette.Entries[i] = Color.FromArgb(i,i,i);
                BitmapImage.Palette = GrayscalePalette;

                //Display image
                pictureBox1.SizeMode = PictureBoxSizeMode.StretchImage;
                pictureBox1.Image = BitmapImage;
            }
        } //CMD_GET_IMAGE
    }


    private void richTextBoxOutput_TextChanged(object sender, EventArgs e)
    {
        this.richTextBoxOutput.ScrollToCaret();
    }

    #endregion

       private void buttonCMD_GET_VERSION_Click(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_GET_VERSION (0x05)\n");

           Int32 elap_time = Environment.TickCount;
           ret = SendCommandReceiveAck(CMD_GET_VERSION, 0, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText(    "Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
               this.richTextBoxOutput.AppendText("Version   : " + this.m_Ack.Param1.ToString("X4") + "." + this.m_Ack.Param2.ToString("X4") + "\n");               
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }


 
       private void buttonCMD_GET_IMAGE_Click(object sender, EventArgs e)
       {
           bool ret;
           String imageView = "FULL SIZE";
           this.richTextBoxOutput.AppendText("+++\n");
           if (this.radioButtonFullSizeImage.Checked)
           {
               this.m_ImageViewSize = 1;
               imageView = "FULL_SIZE";
           }
           if (this.radioButtonHalfSizeImage.Checked)
           {
               this.m_ImageViewSize = 2;
               imageView = "HALF_SIZE";
           }

           this.richTextBoxOutput.AppendText("Send CMD_GET_IMAGE - " + imageView + " (" + this.m_ImageViewSize + ")\n");

           Int32 elap_time = Environment.TickCount;
           ret = SendCommandReceiveAck(CMD_GET_IMAGE, this.m_ImageViewSize, 0, 0, 100000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }

       private void buttonCMD_DEVICE_TEST_Click(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_DEVICE_TEST - DEVICE_ALL (0x00)\n");

           Int32 elap_time = Environment.TickCount;
           ret = SendCommandReceiveAck(0x10, 0, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");

       }

       private void buttonSendCommand_Click(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send Command\n");

           Int32 elap_time = Environment.TickCount;
           ret = SendCommandReceiveAck(Byte.Parse(this.textBoxTestCommand.Text, NumberStyles.HexNumber), (UInt16)Int16.Parse(this.textBoxTestParam1.Text, NumberStyles.HexNumber), UInt16.Parse(this.textBoxTestParam2.Text, NumberStyles.HexNumber), 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }


       private void buttonCMD_FP_REGISTER_START_Click_1(object sender, EventArgs e)
       {
           bool ret;
           MessageBox.Show("Please place finger on sensor");
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_FP_REGISTER_START (0x50)\n");

           Int32 elap_time = Environment.TickCount;
           ushort userID = Convert.ToUInt16(this.textBoxUserID.Text);
           ret = SendCommandReceiveAck(CMD_FP_REGISTER_START, userID, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
               if (this.m_Ack.ErrorCode == 0)
               {
                   MessageBox.Show("Please remove and place same finger on sensor");
                   this.richTextBoxOutput.AppendText("Send CMD_FP_REGISTER_END (0x51)\n");
                   elap_time = Environment.TickCount;
                   ret = SendCommandReceiveAck(CMD_FP_REGISTER_END, Convert.ToUInt16(this.textBoxUserID.Text), 0, 0, 30000);
                   elap_time = Environment.TickCount - elap_time;
                   this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");
                   if (ret)
                   {
                       this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
                       this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
                       this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
                       if (this.m_Ack.ErrorCode == 0)
                           this.richTextBoxOutput.AppendText("Registered user " + this.textBoxUserID.Text + "\n");
                       else
                           this.richTextBoxOutput.AppendText("Unable to register user " + this.textBoxUserID.Text + "\n");
                   }
               }
               else
                   this.richTextBoxOutput.AppendText("Unable to register user " + this.textBoxUserID.Text + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }

       private void buttonCMD_FP_DELETE_Click_1(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_FP_DELETE (0x54)\n");

           Int32 elap_time = Environment.TickCount;
           ushort userID = Convert.ToUInt16(this.textBoxUserID.Text);
           ret = SendCommandReceiveAck(CMD_FP_DELETE, userID, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
               if (this.m_Ack.ErrorCode == 0)
                   this.richTextBoxOutput.AppendText("Deleted user " + this.textBoxUserID.Text + "\n");
               else
                   this.richTextBoxOutput.AppendText("Unable to delete user " + this.textBoxUserID.Text + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }

       private void buttonCMD_FP_VERIFY_Click_1(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_FP_VERIFY (0x55)\n");

           Int32 elap_time = Environment.TickCount;
           ushort userID = Convert.ToUInt16(this.textBoxUserID.Text);
           ret = SendCommandReceiveAck(CMD_FP_VERIFY, userID, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
               if (this.m_Ack.ErrorCode == 0)
                   this.richTextBoxOutput.AppendText("Verified user " + this.textBoxUserID.Text + "\n");
               else
                   this.richTextBoxOutput.AppendText("Unable to verify user " + this.textBoxUserID.Text + "\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }

       private void buttonCMD_FP_IDENTIFY_Click_1(object sender, EventArgs e)
       {
           bool ret;
           this.richTextBoxOutput.AppendText("+++\n");
           this.richTextBoxOutput.AppendText("Send CMD_FP_IDENTIFY (0x56)\n");

           Int32 elap_time = Environment.TickCount;
           ret = SendCommandReceiveAck(CMD_FP_IDENTIFY, 0, 0, 0, 30000);
           elap_time = Environment.TickCount - elap_time;
           this.richTextBoxOutput.AppendText("Packet    : " + this.m_Packet.ToString() + "\n");

           if (ret)
           {            
               this.richTextBoxOutput.AppendText("Ack       : " + this.m_Ack.ToString() + "\n");
               this.richTextBoxOutput.AppendText("Total Time: " + elap_time + "ms\n");
               this.richTextBoxOutput.AppendText("Error Code: " + this.m_Ack.ErrorCode.ToString("X2") + "\n");
               if (this.m_Ack.ErrorCode == 0)
                   this.richTextBoxOutput.AppendText("Result    : Found user " + this.m_Ack.Param1.ToString("D4") + "\n");
               else
                   this.richTextBoxOutput.AppendText("Result    : Unable to identify user\n");
           }
           else
               this.richTextBoxOutput.AppendText("Communications error or timeout\n");
       }
   }

   #region Helper Classes

   public static class UN20BaudRate
    {
        public static byte GetCode(String baudRate)
        {
            switch (Convert.ToInt32(baudRate))
            {   
                case 1200:
                    return 0xBF;
                case 2400:
                    return 0x5F;
                case 9600:
                    return 0x17;
                case 19200:
                    return 0x0B;
                case 38400:
                    return 0x05;
                case 57600:
                    return 0x03;
                case 115200:
                    return 0x01;
                case 230400:
                    return 0xF1;
                case 460800:
                    return 0xF2;
                case 921600:
                    return 0xF3;
                default:
                    return 0x17; //Default to power up baud rate of 9600
            }

        }
    }

    public class Packet
    {
        public Byte Channel;
        public Byte Command;
        public UInt16 Param1;
        public UInt16 Param2;
        public UInt16 LWExtraData;
        public UInt16 HWExtraData;
        public Byte ErrorCode;
        public Byte CheckSum;

        public void reset()
        {
            Channel = 0;
            Command = 0;
            Param1 = 0;
            Param2 = 0;
            LWExtraData = 0;
            HWExtraData = 0;
            ErrorCode = 0;
            CheckSum = 0;
        }

        public override String ToString()
        {
            return (
            Channel.ToString("X2") + "," +
            Command.ToString("X2") + "," +
            Param1.ToString("X4") + "," +
            Param2.ToString("X4") + "," +
            LWExtraData.ToString("X2") + "," +
            HWExtraData.ToString("X2") + "," +
            ErrorCode.ToString("X2") + "," +
            CheckSum.ToString("X2"));
        }


        /*
        void Packet()
        {
            Channel = new Byte();
            Command = new Byte();
            Param1 = new Int16();
            Param2 = new Int16();
            LWExtraData = new Int16();
            HWExtraData = new Int16();
            ErrorCode = new Byte();
            CheckSum = new Byte();
        }
        */
    }
    #endregion
}
