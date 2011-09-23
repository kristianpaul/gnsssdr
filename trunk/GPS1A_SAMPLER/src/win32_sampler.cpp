/*
	GPS 1A Sampler for Windows. Streams GPS IF Samples to file. 
    Copyright (C) 2009  James T. Curran

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
*/


//  Modified on the 21st of Sept 2010:
//		added Circular buffer class to simplify interface
//		embedded the Critical Section handling into the Circular buffer class

#define _CRT_SECURE_NO_DEPRECATE

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>



#include "win32_sampler.h"

// Command line arguments are: Filename (including extension and full or relative path) RecordDuration (in seconds, eg. 100.5 )
int main(int argc, char *argv[]) 
{ 
	///////////////////////////////////////////////////////////
	// What's going on:
	//
	//	main launches two threads: 
	//		CollectFromUSB    :-	deals with getting data from the USB and submitting 
	//								it to a circular buffer. High priority class which 
	//								must keep up to speed with the device.
	//		WriteBufferToFile :-	this extracts data from the circular buffer and packs
	//								it to 4 samples / byte and writes it to a file. A lower
	//								priority thread as the buffer can be made quite large in 
	//								comparison to the device buffer. Here we use typically 
	//								a 16 sec buffer.
	//
	//


	////////////////////////////////////////////////////////////

	//Keep track of file buffer status for read/write operations
	CircularBuffer DeviceDataBuffer;

	//user IO stuff
	char *OutputFileName = "samples.bin";
	double RecordDuration = DEFAULT_RECORD_DURATION;

	//file write thread
	HANDLE FileWriteThreadHandle = NULL;

	//file write thread
	HANDLE USBRecordThreadHandle = NULL;

	//critical section for buffer status
    InitializeCriticalSection(&CheckReadWriteStatus);

	
	//////////////////////////////////////////////////////////////////
	printf("----------\nGNSS IF Sampler\n----------\n");
	/////////////////////////////////////////////
	// COMMAND ARGS
	//first argument is output filename
	if(argc > 1){
		OutputFileName = argv[1];
	}

	//second argument is number of seconds
	if(argc > 2){
		RecordDuration = strtod(argv[2],NULL);
	}

	//////////////////////////////////////////////////////////////
	//make the output file
	if( !ConfigureOutputFile( &DeviceDataBuffer, OutputFileName) )
		return 0;

	////////////////////////////////////////////////////////////
	//configure the usb device
	if( !ConfigureUSB( &DeviceDataBuffer, RecordDuration) )
		return 0;

	////////////////////////////////////////////////////////////////////////////////////
	// indicate the buffer size and requested record duration (debugging only for the moment)
	// these are set in #defines in 'win32_sampler.h'
	printf("Recording %g sec to %g sec buffer\n",RecordDuration,double(FILE_BUFSIZE/FS));

	///////////////////////////////////////////////////////////////////////
	//here we set the priority of 'main' to higher than normal.
	DWORD dwPriClass;
	SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);
	// check priority class
	dwPriClass = GetPriorityClass(GetCurrentProcess());
	//could print to check...
	//printf("Record main priority class: %d\n", dwPriClass);


	//////////////////////////////////////////////////////
	//Launch File Write Thread (defined in 'win32_sampler.h') 
	//This thread runs at the class priority (same as main) 
	//must be launched before the CollectFromUSB thread (we start to empty the buffer before we start to fill it)
	FileWriteThreadHandle = (HANDLE)_beginthread( WriteBufferToFile, 0, &DeviceDataBuffer );

	//////////////////////////////////////////////////////
	//Launch USB record Thread (defined in 'win32_sampler.h')
	// within this thread, it sets it's own priority to 'Time Critical'
	USBRecordThreadHandle = (HANDLE)_beginthread( CollectFromUSB, 0, &DeviceDataBuffer );

	
	//now the two threads run and collect some data
	//..
	//.. some time later...

	//////////////////////////////////////////////
	// Clean up, wait for read thread to finish.
	WaitForSingleObject( USBRecordThreadHandle, INFINITE );
	CloseUSB(&DeviceDataBuffer);
	// once read thread is done, wait for write thread to finish
	// writing whatever is in the buffer..
	WaitForSingleObject( FileWriteThreadHandle, INFINITE );
	fclose(DeviceDataBuffer.OutputFile);

	//delete buffer space 
	__mingw_aligned_free(DeviceDataBuffer.FileBufferPointer);
   
	DeleteCriticalSection(&CheckReadWriteStatus);

	return 0; 
} 
