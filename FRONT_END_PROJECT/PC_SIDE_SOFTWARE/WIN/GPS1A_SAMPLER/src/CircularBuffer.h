/////////////////////////////////////////
// Circular Buffer
// this is a class which handles the circular buffer, it is passed to both the
// CollectFromUSB and the WriteBufferToFile threads, it holds the output file
// handles and the total bytes transferred info etc.

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))

class CircularBuffer{

	public:
		bool FinishedFillingBuffer;
		bool CircularBufferOverFlow;
		bool USBDeviceBufferOverrun;

		LongIntegerType CircularBufferSize;
		int             USBReadSize;
		LongIntegerType InputBufferPos;
		LongIntegerType OutputBufferPos;

		LongIntegerType TotBytesLoaded;
		LongIntegerType TotBytesOutput;

		///int OutputFile;
		FILE *OutputFile;
		char *FileBufferPointer;
		LongIntegerType NumSamplesToLoad;

		struct usb_device *fx2; 
		fx2_config fx2c;
		int fx2Return;

		//dummy print counter
		int PrintoutCtr;
	public:
		CircularBuffer();
		~CircularBuffer();

		LongIntegerType GetAvailableOutputBlockSize();
		bool FinishedLoadingData();
		void AdvanceInputBufferPosition(LongIntegerType ButesLoaded);
		void AdvanceOutputBufferPosition(LongIntegerType BytesWritten);
		void UpdateBufferStatusPrintout(bool Force = 0);
		LongIntegerType CheckRemaingSamplesToLoad();
		void SetFinishedLoadingData();
		bool CheckCircularBufferOverflow();
		LongIntegerType DataLeftInBuffer();
		
};

CircularBuffer::CircularBuffer(){
	
	FinishedFillingBuffer    = 0;
	CircularBufferOverFlow   = 0;

	OutputBufferPos           = 0;
	InputBufferPos            = 0;

	TotBytesOutput = 0;
	TotBytesLoaded  = 0;

	NumSamplesToLoad = LongIntegerType( double(DEFAULT_RECORD_DURATION) * double(FS) );

	CircularBufferSize       = FILE_BUFSIZE;
	USBReadSize              = USB_READ_SIZE;
	fx2                      = NULL;
	fx2Return                = 0;

	//dummy print counter
	PrintoutCtr = 0;

}

CircularBuffer::~CircularBuffer(){};


LongIntegerType CircularBuffer::GetAvailableOutputBlockSize(){

	//check how much we have to write in one continuous block of data : 
	// (either to the end of this buffer, or to the end of the data)
	LongIntegerType TmpVal;
	
	EnterCriticalSection(&CheckReadWriteStatus);
	TmpVal = MIN( CircularBufferSize - OutputBufferPos, TotBytesLoaded - TotBytesOutput );
	LeaveCriticalSection(&CheckReadWriteStatus);
	
	return TmpVal;
};

bool CircularBuffer::FinishedLoadingData(){

	bool TmpVal;

	EnterCriticalSection(&CheckReadWriteStatus);
	TmpVal = FinishedFillingBuffer;
	LeaveCriticalSection(&CheckReadWriteStatus);
	
	return TmpVal;
};

void CircularBuffer::AdvanceOutputBufferPosition(LongIntegerType BytesWritten){

		EnterCriticalSection(&CheckReadWriteStatus);

			//advance buffer pointer and wrap around if necessary
			OutputBufferPos += BytesWritten;
			if(OutputBufferPos >= CircularBufferSize ){
				OutputBufferPos -= CircularBufferSize;
			}
			
			//incurement total output bytes
			TotBytesOutput += BytesWritten;

		LeaveCriticalSection(&CheckReadWriteStatus);

};

void CircularBuffer::AdvanceInputBufferPosition(LongIntegerType BytesLoaded){

	EnterCriticalSection(&CheckReadWriteStatus);

		//increment Buffer pos and total number of bytes xferred from USB
		InputBufferPos += BytesLoaded;
		if( InputBufferPos >= CircularBufferSize ){
			InputBufferPos -= CircularBufferSize;
		}
		TotBytesLoaded  += BytesLoaded;	

		//do overflow check
		if( TotBytesLoaded >= (TotBytesOutput + CircularBufferSize - BytesLoaded) ){ //we will assume that we generally load a fixed size (BytesLoaded), the next load would overrun
			printf("\nError: Circular Buffer overflow.\nFinished loading data.\n");
			CircularBufferOverFlow = 1;
		}
			
	LeaveCriticalSection(&CheckReadWriteStatus);

}

LongIntegerType CircularBuffer::CheckRemaingSamplesToLoad(){

	LongIntegerType TmpVal;
	EnterCriticalSection(&CheckReadWriteStatus);
		TmpVal = NumSamplesToLoad - TotBytesLoaded;
	LeaveCriticalSection(&CheckReadWriteStatus);

	return TmpVal;
};

void CircularBuffer::UpdateBufferStatusPrintout(bool Force){

	EnterCriticalSection(&CheckReadWriteStatus);

	// do an update of the current buffer status and total read time
	int ItersPerPrint = 1000000;
	PrintoutCtr = (PrintoutCtr + 1)%ItersPerPrint;
	if(PrintoutCtr == ItersPerPrint-1 || Force){
		printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
		printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
		printf("Collected: %8.3f seconds.   ",double(2*TotBytesLoaded/FS));
		printf("Buffer Usage: % 6.2f%%",100.0 * double(TotBytesLoaded-TotBytesOutput) / double(CircularBufferSize));
	}

	LeaveCriticalSection(&CheckReadWriteStatus);

};


void CircularBuffer::SetFinishedLoadingData(){

	EnterCriticalSection(&CheckReadWriteStatus);
		FinishedFillingBuffer = 1;
	LeaveCriticalSection(&CheckReadWriteStatus);
};

bool CircularBuffer::CheckCircularBufferOverflow(){

	return CircularBufferOverFlow;

};


LongIntegerType CircularBuffer::DataLeftInBuffer(){
	
	LongIntegerType TmpVal;

	EnterCriticalSection(&CheckReadWriteStatus);
		TmpVal = TotBytesLoaded - TotBytesOutput;
	LeaveCriticalSection(&CheckReadWriteStatus);


	return TmpVal;
};

