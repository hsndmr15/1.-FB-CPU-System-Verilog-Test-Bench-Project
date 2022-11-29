`timescale 1ns / 1ps

module tb_fbcpu();
    `define NULL 0 
	reg clk = 0;
	reg rst;
	 
	parameter ADDRESS_WIDTH = 6;
	parameter DATA_WIDTH = 10;
	 
	wire [ADDRESS_WIDTH-1:0] addr_toRAM;
	wire [DATA_WIDTH-1:0] data_toRAM, data_fromRAM;
	wire [ADDRESS_WIDTH-1:0] pCounter;
	wire wrEn;

	blram #(ADDRESS_WIDTH, 64) blram(
		  .clk(clk),
		  .rst(rst),
		  .i_we(wrEn),
		  .i_addr(addr_toRAM),
		  .i_ram_data_in(data_toRAM),
		  .o_ram_data_out(data_fromRAM)
		);
		
	FBCPU #(
        ADDRESS_WIDTH,
        DATA_WIDTH
    ) FBCPU_Inst(
        .clk(clk), 
        .rst(rst), 
        .MDRIn(data_toRAM), 
        .RAMWr(wrEn), 
        .MAR(addr_toRAM), 
        .MDROut(data_fromRAM), 
        .PC(pCounter)
    );
	
	always #5 clk = !clk;
	class dosyaSinifi;
	
		integer fileDescriptor    ; // file handler
		integer scanFile    ; // file handler	   
		int lineCount;
		logic fileInitialized ;
		logic fileComplated ;
		logic [7:0]memAddr;
		logic [21:0]data;
		
		string acilanDosyaAdi;
	
		function new();
			lineCount = 0  ;
			fileInitialized = 0  ;
			fileComplated  = 0  ;
			memAddr = 0  ;
			data = 0  ;
		endfunction

		function int dosyayiInitializeEt( string girisDosyaAdi);
			fileDescriptor = $fopen(girisDosyaAdi, "r");
			if (fileDescriptor == `NULL) begin
				$display("DOSYA ACILAMADI !\n ");
				fileInitialized = 0;
				return 0;
			end else begin
				$display("DOSYA ACILDI !" );
				$display("ACILAN DOSYA ADI: %d \n" , girisDosyaAdi);
				acilanDosyaAdi = girisDosyaAdi; 
				fileInitialized = 1;
				return 1;
			end

        endfunction
		function int dosyadanOku( );
			if (fileInitialized == 1) begin
				if(fileComplated==0) begin
					 scanFile = $fscanf(fileDescriptor, "%x %x\n", memAddr, data); 
					 lineCount++;

					 
					if ($feof(fileDescriptor)) begin
						fileComplated=1;
						$display("OKUNAN DOSYA ADI: %d" , acilanDosyaAdi);
						$display("OKUNAN SATIR SAYISI : %d \n" ,lineCount );
					end
					return 1;
				end else begin
				    fileComplated=0;
				    lineCount = 0;
				    return 0 ;
				end
			end
        endfunction
	endclass
	
	class testSinifi extends dosyaSinifi;
		int durum1;
		int durum2;
		int testNo;
		
		dosyaSinifi girisDosyasi;
		dosyaSinifi cikisDosyasi;
		
		function new();
			testNo = 0;
			girisDosyasi =new;
			cikisDosyasi =new;
			
		endfunction
		
		function int testNoAyarla( int girisTestNo );
			testNo = girisTestNo;
			return 0;
		endfunction
		
		function int testInitializeEt(  );
			if(testNo == 0)begin
				girisDosyasi.dosyayiInitializeEt("input1.txt");
				cikisDosyasi.dosyayiInitializeEt("output1.txt");
			end else if ( testNo == 1 )begin
				girisDosyasi.dosyayiInitializeEt("input2.txt");
				cikisDosyasi.dosyayiInitializeEt("output2.txt");
			end else if ( testNo == 2 ) begin
				girisDosyasi.dosyayiInitializeEt("input3.txt");
				cikisDosyasi.dosyayiInitializeEt("output3.txt");
			end
		endfunction
		
		function int kontrolEt( reg [7:0] memLocation, reg [21:0] expectedValue );
			
				durum1 = blram.memory[memLocation];
				durum2 = expectedValue;
				if(durum1 == durum2)begin
					$display("TEST BASARILI !  ISLEMCI CIKTISI => %d , BEKLENEN CIKTI => %d \n",durum1 , durum2 );
				end else begin
					$display("TEST BASARISIZ !  ISLEMCI CIKTISI => %d , BEKLENEN CIKTI => %d\n",durum1 , durum2 );
				end
		endfunction
			
	endclass
	
	testSinifi test = new;
	initial begin 
		clk = 0;
		rst = 0;
		
		for (int i = 0; i<3 ;i = i+1) begin
			$display("Su anki Test no:  %d\n",(i+1) );
			test.testNoAyarla(i);
			test.testInitializeEt();
			while(test.girisDosyasi.dosyadanOku() == 1) begin
				blram.memory[test.girisDosyasi.memAddr] = test.girisDosyasi.data;
			end
	
			rst <= #1 1;
			repeat(10) @(posedge clk );
			rst <= #1 0;
			repeat(10000) @(posedge clk );
			while (test.cikisDosyasi.dosyadanOku() == 1) begin
			    $display("TEST SONUCU:" );
				test.kontrolEt(test.cikisDosyasi.memAddr, test.cikisDosyasi.data);
				
			
			end
			$display("BITIRILEN TEST  %d\n",(i+1) );
			
		end
		$display("SIMULASYON TAMAMLANDI ! " );
		$finish;
    end
endmodule
