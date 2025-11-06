/*
 * Copyright (C) 2013 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.secugen.u20_bt_android_ble_demo;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v4.content.PermissionChecker;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ExpandableListView;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.SimpleExpandableListAdapter;
import android.widget.TextView;
import android.os.Handler;
import android.os.Message;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import com.secugen.fmssdk.*;

class WSQInfoClass {
    int width = 0;
    int height = 0;
    int pixelDepth = 0;
    int ppi = 0;
    int lossyFlag = 0;
}

/**
 * For a given BLE device, this Activity provides the user interface to connect, display data,
 * and display GATT services and characteristics supported by the device.  The Activity
 * communicates with {@code BluetoothLeService}, which in turn interacts with the
 * Bluetooth LE API.
 */
public class DeviceControlActivity extends Activity {
    private final static String TAG = DeviceControlActivity.class.getSimpleName();

    public static final String EXTRAS_DEVICE_NAME = "DEVICE_NAME";
    public static final String EXTRAS_DEVICE_ADDRESS = "DEVICE_ADDRESS";

    private TextView mConnectionState;
    //private TextView mDataField;
    private String mDeviceName;
    private String mDeviceAddress;
    private ExpandableListView mGattServicesList;
    private BluetoothLeService mBluetoothLeService;
    private ArrayList<ArrayList<BluetoothGattCharacteristic>> mGattCharacteristics =
            new ArrayList<ArrayList<BluetoothGattCharacteristic>>();
    private boolean mConnected = false;
    private BluetoothGattCharacteristic mNotifyCharacteristic;

    private final String LIST_NAME = "NAME";
    private final String LIST_UUID = "UUID";

    // Message types
    public static final int MESSAGE_READ_RESPONSE = 1;
    public static final int MESSAGE_WRITE_RESPONSE = 2;
    public static final int MESSAGE_READ_PROGRESS = 3;
    public static final int MESSAGE_TOAST = 4;

    public static final String TOAST = "toast";

    private TextView mTextMAC;
    private TextView mTextViewStatus;
    private ImageView mImageViewResult;
    private ImageView mImageViewFingerprint;

    private CheckBox mCheckFullSize;
    private CheckBox mCheckWSQ;
    private ProgressBar mProgress;
    private TextView mTextProgress;

    private ListView mConversationView;
    private ArrayAdapter<String> mConversationArrayAdapter;

    // libsgwsq-jni.so
    static {
        System.loadLibrary("sgwsq-jni");
    }

    public native byte[] jniSgWSQDecode(WSQInfoClass WSQInfoClass, byte[] wsqImage, int wsqImageLength);

    // Code to manage Service lifecycle.
    private final ServiceConnection mServiceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {
            mBluetoothLeService = ((BluetoothLeService.LocalBinder) service).getService();
            if (!mBluetoothLeService.initialize(mResponseHandler)) {
                Log.e(TAG, "Unable to initialize Bluetooth");
                finish();
            }
            // Automatically connects to the device upon successful start-up initialization.
            mBluetoothLeService.connect(mDeviceAddress);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            mBluetoothLeService = null;
        }
    };

    // Handles various events fired by the Service.
    // ACTION_GATT_CONNECTED: connected to a GATT server.
    // ACTION_GATT_DISCONNECTED: disconnected from a GATT server.
    // ACTION_GATT_SERVICES_DISCOVERED: discovered GATT services.
    // ACTION_DATA_AVAILABLE: received data from the device.  This can be a result of read
    //                        or notification operations.
    private final BroadcastReceiver mGattUpdateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (BluetoothLeService.ACTION_GATT_CONNECTED.equals(action)) {
                mConnected = true;
                updateConnectionState(R.string.connected);
                invalidateOptionsMenu();

                mTextMAC.setText(mDeviceAddress);
                displayData("Connecting to " + mDeviceName);
            } else if (BluetoothLeService.ACTION_GATT_DISCONNECTED.equals(action)) {
                mConnected = false;
                updateConnectionState(R.string.disconnected);
                invalidateOptionsMenu();
                clearUI();
            } else if (BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED.equals(action)) {
                // Show all the supported services and characteristics on the user interface.
                //displayGattServices(mBluetoothLeService.getSupportedGattServices());
            } else if (BluetoothLeService.ACTION_DATA_AVAILABLE.equals(action)) {
                displayData(intent.getStringExtra(BluetoothLeService.EXTRA_DATA));
            }
        }
    };

    // If a given GATT characteristic is selected, check for supported features.  This sample
    // demonstrates 'Read' and 'Notify' features.  See
    // http://d.android.com/reference/android/bluetooth/BluetoothGatt.html for the complete
    // list of supported characteristic features.
    private final ExpandableListView.OnChildClickListener servicesListClickListner =
            new ExpandableListView.OnChildClickListener() {
                @Override
                public boolean onChildClick(ExpandableListView parent, View v, int groupPosition,
                                            int childPosition, long id) {
                    if (mGattCharacteristics != null) {
                        final BluetoothGattCharacteristic characteristic =
                                mGattCharacteristics.get(groupPosition).get(childPosition);
                        final int charaProp = characteristic.getProperties();
                        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_READ) > 0) {
                            // If there is an active notification on a characteristic, clear
                            // it first so it doesn't update the data field on the user interface.
                            if (mNotifyCharacteristic != null) {
                                mBluetoothLeService.setCharacteristicNotification(
                                        mNotifyCharacteristic, false);
                                mNotifyCharacteristic = null;
                            }
                            mBluetoothLeService.readCharacteristic(characteristic);
                        }
                        if ((charaProp | BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) {
                            mNotifyCharacteristic = characteristic;
                            mBluetoothLeService.setCharacteristicNotification(
                                    characteristic, true);
                        }
                        return true;
                    }
                    return false;
                }
    };

    private void clearUI() {
        //mGattServicesList.setAdapter((SimpleExpandableListAdapter) null);
        mTextMAC.setText("");
        displayData(getString(R.string.no_data));
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        // check permissions
        String[] permissions = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (String permission: permissions) {
                int result = PermissionChecker.checkSelfPermission(this, permission);

                if (result == PermissionChecker.PERMISSION_GRANTED) {
                    ;// skip
                } else {
                    doRequestPermission();
                }
            }
        }

        super.onCreate(savedInstanceState);
        //setContentView(R.layout.gatt_services_characteristics);
        setContentView(R.layout.u20bt_ble_test);

        final Intent intent = getIntent();
        mDeviceName = intent.getStringExtra(EXTRAS_DEVICE_NAME);
        mDeviceAddress = intent.getStringExtra(EXTRAS_DEVICE_ADDRESS);

        // Sets up UI references.
        /*
        ((TextView) findViewById(R.id.device_address)).setText(mDeviceAddress);
        mGattServicesList = (ExpandableListView) findViewById(R.id.gatt_services_list);
        mGattServicesList.setOnChildClickListener(servicesListClickListner);
        mConnectionState = (TextView) findViewById(R.id.connection_state);
        mDataField = (TextView) findViewById(R.id.data_value);
        */

        mTextMAC = (TextView) findViewById(R.id.textMAC);
        mTextViewStatus = (TextView) findViewById(R.id.textViewStatus);
        mImageViewResult = (ImageView) findViewById(R.id.imageViewResult);
        mImageViewFingerprint = (ImageView) findViewById(R.id.imageViewFingerprint);
        mCheckFullSize = (CheckBox) findViewById(R.id.checkBoxFullSize);
        mCheckWSQ = (CheckBox) findViewById(R.id.checkBoxWSQFormat);
        mProgress = (ProgressBar) findViewById(R.id.progressBar);
        mTextProgress = (TextView) findViewById(R.id.textProgress);

        getActionBar().setTitle(mDeviceName);
        getActionBar().setDisplayHomeAsUpEnabled(true);
        Intent gattServiceIntent = new Intent(this, BluetoothLeService.class);
        bindService(gattServiceIntent, mServiceConnection, BIND_AUTO_CREATE);

        // Initialize the array adapter for the conversation thread
        mConversationArrayAdapter = new ArrayAdapter<String>(this, R.layout.message);
        mConversationView = (ListView) findViewById(R.id.data_value);
        mConversationView.setAdapter(mConversationArrayAdapter);

        mTextMAC.setText(mDeviceAddress);
    }

    @Override
    protected void onResume() {
        super.onResume();
        registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter());
        if (mBluetoothLeService != null) {
            final boolean result = mBluetoothLeService.connect(mDeviceAddress);
            Log.d(TAG, "Connect request result=" + result);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        unregisterReceiver(mGattUpdateReceiver);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unbindService(mServiceConnection);
        mBluetoothLeService = null;
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.gatt_services, menu);
        if (mConnected) {
            menu.findItem(R.id.menu_connect).setVisible(false);
            menu.findItem(R.id.menu_disconnect).setVisible(true);
        } else {
            menu.findItem(R.id.menu_connect).setVisible(true);
            menu.findItem(R.id.menu_disconnect).setVisible(false);
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch(item.getItemId()) {
            case R.id.menu_connect:
                mBluetoothLeService.connect(mDeviceAddress);
                return true;
            case R.id.menu_disconnect:
                mBluetoothLeService.disconnect();
                return true;
            case android.R.id.home:
                onBackPressed();
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void doRequestPermission() {
        String[] permissions = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};

        // enable BluetoothDevice.ACTION_FOUND filter for new device scan
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE+Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, permissions, 1);
        }
    }

    private void updateConnectionState(final int resourceId) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                //mConnectionState.setText(resourceId);
            }
        });
    }

    private void displayData(String data) {
        if (data != null) {
            mConversationArrayAdapter.add(data);
        }
    }

    // Demonstrates how to iterate through the supported GATT Services/Characteristics.
    // In this sample, we populate the data structure that is bound to the ExpandableListView
    // on the UI.
    private void displayGattServices(List<BluetoothGattService> gattServices) {
        if (gattServices == null) return;
        String uuid = null;
        String unknownServiceString = getResources().getString(R.string.unknown_service);
        String unknownCharaString = getResources().getString(R.string.unknown_characteristic);
        ArrayList<HashMap<String, String>> gattServiceData = new ArrayList<HashMap<String, String>>();
        ArrayList<ArrayList<HashMap<String, String>>> gattCharacteristicData
                = new ArrayList<ArrayList<HashMap<String, String>>>();
        mGattCharacteristics = new ArrayList<ArrayList<BluetoothGattCharacteristic>>();

        // Loops through available GATT Services.
        for (BluetoothGattService gattService : gattServices) {
            HashMap<String, String> currentServiceData = new HashMap<String, String>();
            uuid = gattService.getUuid().toString();
            currentServiceData.put(
                    LIST_NAME, U20BTGattAttributes.lookup(uuid, unknownServiceString));
            currentServiceData.put(LIST_UUID, uuid);
            gattServiceData.add(currentServiceData);

            ArrayList<HashMap<String, String>> gattCharacteristicGroupData =
                    new ArrayList<HashMap<String, String>>();
            List<BluetoothGattCharacteristic> gattCharacteristics =
                    gattService.getCharacteristics();
            ArrayList<BluetoothGattCharacteristic> charas =
                    new ArrayList<BluetoothGattCharacteristic>();

            // Loops through available Characteristics.
            for (BluetoothGattCharacteristic gattCharacteristic : gattCharacteristics) {
                charas.add(gattCharacteristic);
                HashMap<String, String> currentCharaData = new HashMap<String, String>();
                uuid = gattCharacteristic.getUuid().toString();
                currentCharaData.put(
                        LIST_NAME, U20BTGattAttributes.lookup(uuid, unknownCharaString));
                currentCharaData.put(LIST_UUID, uuid);
                gattCharacteristicGroupData.add(currentCharaData);
            }
            mGattCharacteristics.add(charas);
            gattCharacteristicData.add(gattCharacteristicGroupData);
        }

        SimpleExpandableListAdapter gattServiceAdapter = new SimpleExpandableListAdapter(
                this,
                gattServiceData,
                android.R.layout.simple_expandable_list_item_2,
                new String[] {LIST_NAME, LIST_UUID},
                new int[] { android.R.id.text1, android.R.id.text2 },
                gattCharacteristicData,
                android.R.layout.simple_expandable_list_item_2,
                new String[] {LIST_NAME, LIST_UUID},
                new int[] { android.R.id.text1, android.R.id.text2 }
        );
        mGattServicesList.setAdapter(gattServiceAdapter);
    }

    private static IntentFilter makeGattUpdateIntentFilter() {
        final IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_CONNECTED);
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_DISCONNECTED);
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED);
        intentFilter.addAction(BluetoothLeService.ACTION_DATA_AVAILABLE);
        return intentFilter;
    }

    public void onClickGetFirmwareVersion(View v){
        mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdGetVersion()));
        mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdGetVersion());
    }
    public void onClickRegister1(View v){
        mImageViewResult.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("+++");
        mConversationArrayAdapter.add("Register Capture 1");
        TextView view = (TextView) findViewById(R.id.edit_text_out);
        String userID = view.getText().toString();
        if (userID.length() == 4)
        {
            int validUserID = getStringToValidUserID(userID);
            if (validUserID != -1) {
                boolean isAdmin = false;
                mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPRegisterStart(validUserID, isAdmin)));
                mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPRegisterStart(validUserID, isAdmin));
            } else {
                mConversationArrayAdapter.add("User ID digits should be an even number, and only numerals are allowed for each digit.");
                mTextViewStatus.setText("User ID digits should be an even number, and only numerals are allowed for each digit.");
            }
        } else {
            mConversationArrayAdapter.add("Please enter a four-digit number.");
            mTextViewStatus.setText("Please enter a four-digit number.");
        }
    }
    public void onClickRegister2(View v){
        mImageViewResult.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("Register Capture 2");
        mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPRegisterEnd()));
        mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPRegisterEnd());
    }
    public void onClickVerify(View v){
        mImageViewResult.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("+++");
        mConversationArrayAdapter.add("Verify");
        TextView view = (TextView) findViewById(R.id.edit_text_out);
        String userID = view.getText().toString();
        if (userID.length() == 4)
        {
            int validUserID = getStringToValidUserID(userID);
            if (validUserID != -1) {
                mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPVerify(validUserID)));
                mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPVerify(validUserID));
            } else {
                mConversationArrayAdapter.add("User ID digits should be an even number, and only numerals are allowed for each digit.");
                mTextViewStatus.setText("User ID digits should be an even number, and only numerals are allowed for each digit.");
            }
        } else {
            mConversationArrayAdapter.add("Please enter a four-digit number.");
            mTextViewStatus.setText("Please enter a four-digit number.");
        }
    }
    public void onClickDelete(View v){
        mImageViewResult.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("+++");
        mConversationArrayAdapter.add("Delete User");
        TextView view = (TextView) findViewById(R.id.edit_text_out);
        String userID = view.getText().toString();
        if (userID.length() == 4)
        {
            int validUserID = getStringToValidUserID(userID);
            if (validUserID != -1) {
                mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPDelete(validUserID)));
                mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPDelete(validUserID));
            } else {
                mConversationArrayAdapter.add("User ID digits should be an even number, and only numerals are allowed for each digit.");
                mTextViewStatus.setText("User ID digits should be an even number, and only numerals are allowed for each digit.");
            }
        } else {
            mConversationArrayAdapter.add("Please enter a four-digit number.");
            mTextViewStatus.setText("Please enter a four-digit number.");
        }
    }
    public void onClickIdentify(View v){
        mImageViewResult.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("+++");
        mConversationArrayAdapter.add("Identify User");
        mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPIdentify()));
        mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPIdentify());
    }
    public void onClickCapture(View v){
        mImageViewFingerprint.setImageResource(R.drawable.status_blank);
        mConversationArrayAdapter.add("+++");
        if (mCheckWSQ.isChecked()) {
            mConversationArrayAdapter.add("Capture use WSQ format");
            mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPCaptureUseWSQ(mCheckFullSize.isChecked() ? FMSAPI.IMAGE_SIZE_FULL:FMSAPI.IMAGE_SIZE_HALF)));
            mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPCaptureUseWSQ(mCheckFullSize.isChecked() ? FMSAPI.IMAGE_SIZE_FULL:FMSAPI.IMAGE_SIZE_HALF));
        } else {
            mConversationArrayAdapter.add("Capture");
            mConversationArrayAdapter.add("SEND: " + bytesToHexString(FMSAPI.cmdFPCapture(mCheckFullSize.isChecked() ? FMSAPI.IMAGE_SIZE_FULL:FMSAPI.IMAGE_SIZE_HALF)));
            mBluetoothLeService.writeCustomCharacteristic(FMSAPI.cmdFPCapture(mCheckFullSize.isChecked() ? FMSAPI.IMAGE_SIZE_FULL:FMSAPI.IMAGE_SIZE_HALF));
        }
    }

    //Display byte array as hex string
    private static String bytesToHexString(byte[] bytes){
        StringBuilder sb = new StringBuilder();
        for(byte b : bytes){
            sb.append(String.format("%02x ", b&0xff));
        } return sb.toString();
    }

    //Display byte array as hex string
    private static String bytesToHexString(byte[] bytes, int sizes){
        StringBuilder sb = new StringBuilder();
        for(int i = 0; i < sizes; i++){
            sb.append(String.format("%02x", bytes[i]&0xff));
        }
        return sb.toString();
    }

    //Display short as hex string
    private static String shortToHexString(short data){
        StringBuilder sb = new StringBuilder();

        sb.append(String.format("%02X", (data >> 8)&0xff));
        sb.append(String.format("%02X", (data     )&0xff));

        return sb.toString();
    }

    // Assume a number less than four digits.
    private static int getStringToValidUserID(String s){
        int strLen = s.length();
        int nValidUserID = 0, pos = 0;
        if (strLen%2 !=0 ) // fail if odd
            return -1;

        for (int i = 0; i < strLen; i+= 2) {
            nValidUserID = (nValidUserID << (pos*8)) | ((Character.digit(s.charAt(i),16) << 4) + Character.digit(s.charAt(i+1), 16));
            pos++;
        }

        return nValidUserID;
    }

    private final Handler mResponseHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MESSAGE_READ_RESPONSE:
                    Log.d(TAG, "mResponseHandler: MESSAGE_READ_RESPONSE");

                    byte[] readResponseBuf = (byte[]) msg.obj;

                    FMSHeader rHeader = new FMSHeader(readResponseBuf);
                    FMSData data = null;
                    if (!(rHeader.pkt_command == FMSAPI.CMD_FP_CAPTURE && rHeader.pkt_param1 == 0x0001)) // Not full size capture, full size image using file i/o
                        data = new FMSData(readResponseBuf);

                    switch(rHeader.pkt_command)
                    {
                        case FMSAPI.CMD_GET_VERSION:
                        case FMSAPI.CMD_FP_REGISTER_END:
                            mTextViewStatus.setText("" + FMSAPI.parseResponse(readResponseBuf));
                            if (rHeader.pkt_error == FMSAPI.ERR_NONE) {
                                mImageViewResult.setImageResource(R.drawable.status_recognized_48dp);
                            } else {
                                mImageViewResult.setImageResource(R.drawable.status_not_recognized_48dp);
                            }
                            break;

                        case FMSAPI.CMD_FP_REGISTER_START:
                            switch(rHeader.pkt_error)
                            {
                                case FMSAPI.ERR_NONE:
                                    mTextViewStatus.setText(new String("Capture 1 OK. Place same finger and click Register 2"));
                                    break;
                                case FMSAPI.ERR_ALREADY_REGISTERED_USER:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " already registered"));
                                    mImageViewResult.setImageResource(R.drawable.status_error_48dp);
                                    break;
                                default:
                                    mTextViewStatus.setText(new String("Error: [" + Integer.toHexString((int) rHeader.pkt_error)  + "]"));
                                    mImageViewResult.setImageResource(R.drawable.status_error_48dp);
                                    break;
                            }
                            break;
                        case FMSAPI.CMD_FP_VERIFY:
                            //Bitmap bImage;
                            switch(rHeader.pkt_error)
                            {
                                case FMSAPI.ERR_NONE:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " verified. Score:[" + rHeader.pkt_param2 + "]"));
                                    mImageViewResult.setImageResource(R.drawable.status_recognized_48dp);
                                    break;
                                case FMSAPI.ERR_VERIFY_FAILED:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " not verified. Score:[" + rHeader.pkt_param2 + "]"));
                                    mImageViewResult.setImageResource(R.drawable.status_not_recognized_48dp);
                                    break;
                                case FMSAPI.ERR_USER_NOT_FOUND:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " not found."));
                                    mImageViewResult.setImageResource(R.drawable.status_error_48dp);
                                    break;
                                default:
                                    mTextViewStatus.setText(new String("Error: [" + Integer.toHexString((int) rHeader.pkt_error)  + "]"));
                                    mImageViewResult.setImageResource(R.drawable.status_error_48dp);
                            }
                            break;
                        case FMSAPI.CMD_FP_IDENTIFY:
                            switch(rHeader.pkt_error)
                            {
                                case FMSAPI.ERR_NONE:
                                    mTextViewStatus.setText(new String("User " + ((data.d_length > 0) ? bytesToHexString(data.get(), data.d_length): shortToHexString(rHeader.pkt_param1)) + " identified. Score:[" + rHeader.pkt_param2 + "]" ));
                                    mImageViewResult.setImageResource(R.drawable.status_recognized_48dp);
                                    break;
                                case FMSAPI.ERR_IDENTIFY_FAILED:
                                    mTextViewStatus.setText(new String("User not found."));
                                    mImageViewResult.setImageResource(R.drawable.status_not_recognized_48dp);
                                    break;
                                default:
                                    mTextViewStatus.setText(new String("Error: [" + Integer.toHexString((int) rHeader.pkt_error)  + "]"));
                            }
                            break;
                        case FMSAPI.CMD_FP_CAPTURE:
                            switch(rHeader.pkt_error)
                            {
                                case FMSAPI.ERR_NONE:
                                    mImageViewResult.setImageResource(R.drawable.status_recognized_48dp);
                                    if (((rHeader.pkt_param1 >> 8) & 0xFF) != 0) {
                                        WSQInfoClass myInfo = new WSQInfoClass();
                                        byte[] imgBuf = data.get();
                                        byte[] rtValue = jniSgWSQDecode(myInfo, imgBuf, data.d_length);

                                        displayData("WSQ Information: ");
                                        displayData("     width: " + myInfo.width + "   height: " + myInfo.height);
                                        displayData("     ppi: " + myInfo.ppi + "   pixeldepth: " + myInfo.pixelDepth);
                                        displayData("     bitrate: " + "15:1 (0.75)" );
                                        displayData("     wsq size: " + data.d_length);

                                        FMSImage Img = new FMSImage(rtValue, myInfo.width*myInfo.height);
                                        mImageViewFingerprint.setImageBitmap(Img.get());
                                    } else {
                                        //FMSImage Img = new FMSImage(data.get(), data.d_length);
                                        FMSImage Img = null;
                                        if ((rHeader.pkt_param1 & 0xFF) == 0x01) { // full size
                                            FMSImageSave fmsimgsave = new FMSImageSave();
                                            Img = new FMSImage(fmsimgsave.getImgBuf(), fmsimgsave.getImgSize());
                                        } else { // half size
                                            Img = new FMSImage(data.get(), data.d_length);
                                        }

                                        displayData("Image Information: ");
                                        displayData("     width: " + Img.getmWidth() + "   height: " + Img.getmHeight());
                                        displayData("     image size: " + Img.getmWidth()*Img.getmHeight());

                                        mImageViewFingerprint.setImageBitmap(Img.get());
                                    }
                                    break;
                                default:
                                    mTextViewStatus.setText(new String("Error: [" + Integer.toHexString((int) rHeader.pkt_error)  + "]"));
                            }
                            break;
                        case FMSAPI.CMD_FP_DELETE:
                            switch(rHeader.pkt_error)
                            {
                                case FMSAPI.ERR_NONE:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " deleted"));
                                    mImageViewResult.setImageResource(R.drawable.status_recognized_48dp);
                                    break;
                                case FMSAPI.ERR_USER_NOT_FOUND:
                                    mTextViewStatus.setText(new String("User " + shortToHexString(rHeader.pkt_param1) + " not found"));
                                    mImageViewResult.setImageResource(R.drawable.status_not_recognized_48dp);
                                    break;
                                default:
                                    mTextViewStatus.setText(new String("Error: [" + Integer.toHexString((int) rHeader.pkt_error)  + "]"));
                                    mImageViewResult.setImageResource(R.drawable.status_not_recognized_48dp);
                                    break;
                            }
                            break;
                    }

                    break;
                case MESSAGE_WRITE_RESPONSE:
                    Log.d(TAG, "mResponseHandler: MESSAGE_WRITE_RESPONSE");
                    byte[] writeResponseBuf = (byte[]) msg.obj;
                    FMSHeader wHeader = new FMSHeader(writeResponseBuf);

                    final StringBuilder stringBuilder = new StringBuilder(msg.arg1);
                    for(byte byteChar : writeResponseBuf)
                        stringBuilder.append(String.format("%02X ", byteChar));
                    Log.d(TAG, String.format("Write Response: %s // send %s", stringBuilder.toString(), (msg.arg2 != FMSAPI.ERR_NONE ? "failed":"success")));

                    if (msg.arg2 == FMSAPI.ERR_NONE) {
                        ;// nothing to do
                    } else {
                        switch (wHeader.pkt_command) {
                            case FMSAPI.CMD_GET_VERSION:
                                displayData("CMD_GET_VERSION command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_REGISTER_START:
                                displayData("CMD_FP_REGISTER_START command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_REGISTER_END:
                                displayData("CMD_FP_REGISTER_END command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_VERIFY:
                                displayData("CMD_FP_VERIFY command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_IDENTIFY:
                                displayData("CMD_FP_IDENTIFY command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_DELETE:
                                displayData("CMD_FP_DELETE command transfer failed.");
                                break;
                            case FMSAPI.CMD_FP_CAPTURE:
                                displayData("CMD_FP_CAPTURE command transfer failed.");
                                break;
                        }
                    }
                    break;
                case MESSAGE_READ_PROGRESS:
                    final int progressPos = msg.arg1;
                    final Handler progressHandler = new Handler();
                    //Start progressing
                    new Thread(new Runnable() {
                        public void run() {
                            if (progressPos >= 0 && progressPos <= 100) {
                                progressHandler.post(new Runnable() {
                                    public void run() {
                                        mProgress.setProgress(progressPos);
                                        mTextProgress.setText(String.format("%d %%", progressPos));
                                   }
                                });
                            }
                        }
                    }).start();
                    break;
                case MESSAGE_TOAST:
                    Toast.makeText(getApplicationContext(), msg.getData().getString(TOAST),
                            Toast.LENGTH_SHORT).show();
                    break;
            }
        }
    };
}
