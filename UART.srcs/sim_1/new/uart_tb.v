// Francesco DE CANIO - francesco_decanio@hotmail.com
// UART verification bench: exercises transmission and reception of
// serial bytes at a reduced simulation clock frequency.

`timescale 1ns / 10ps

 
module uart_tb ();
 
  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter clock_period_ns = 100;
  parameter clocks_per_bit  = 87;
  parameter bit_period_ns   = 8600;
   
  reg clock_signal = 0;
  reg transmit_valid = 0;
  wire transmit_done;
  reg [7:0] transmit_byte = 0;
  reg receive_serial = 1;
  wire serial_bus;
  wire [7:0] received_byte;

   
 
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
       
      // Send Start Bit
      receive_serial <= 1'b0;
      #(bit_period_ns);
      #1000;
       
       
      // Send Data Byte
      for (ii=0; ii<8; ii=ii+1)
        begin
          receive_serial <= i_Data[ii];
          #(bit_period_ns);
        end
       
      // Send Stop Bit
      receive_serial <= 1'b1;
      #(bit_period_ns);
     end
  endtask // UART_WRITE_BYTE
   
   
  uart_rx #(.CLKS_PER_BIT(clocks_per_bit)) UART_RX_INST
    (.i_Clock(clock_signal),
     .i_Rx_Serial(serial_bus),
     .o_Rx_DV(),
     .o_Rx_Byte(received_byte)
     );
   
  uart_tx #(.CLKS_PER_BIT(clocks_per_bit)) UART_TX_INST
    (.i_Clock(clock_signal),
     .i_Tx_DV(transmit_valid),
     .i_Tx_Byte(transmit_byte),
     .o_Tx_Active(),
     .o_Tx_Serial(serial_bus),
     .o_Tx_Done(transmit_done)
     );
 
   
  always
    #(clock_period_ns/2) clock_signal <= !clock_signal;
 
   
  // Main Testing:
  initial
    begin
    
    $display("Simulazione partita");
       
      // Tell UART to send a command (exercise Tx)
      @(posedge clock_signal);
      @(posedge clock_signal);
      transmit_valid <= 1'b1;
      transmit_byte <= 8'hAB;
      @(posedge clock_signal);
      transmit_valid <= 1'b0;
      @(posedge transmit_done);
       
      // Send a command to the UART (exercise Rx)
      @(posedge clock_signal);
      UART_WRITE_BYTE(8'h3F);
      @(posedge clock_signal);
             
      // Check that the correct command was received
      if (received_byte == 8'h3F)
        $display("MESSAGE Test Passed - Correct Byte Received");
      else
        $display("MESSAGE Test Failed - Incorrect Byte Received");
       
    end
   
endmodule
