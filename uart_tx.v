// Francesco DE CANIO - francesco_decanio@hotmail.com
// UART transmitter: serializes each 8-bit data word using one start
// bit, one stop bit and no parity bit.

module uart_tx 
  #(parameter CLKS_PER_BIT = 1085 )
  (
   input       i_Clock,
   input       i_Tx_DV,
   input [7:0] i_Tx_Byte, 
   output      o_Tx_Active,
   output reg  o_Tx_Serial,
   output      o_Tx_Done
   );

  localparam integer COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg [2:0]    transmitter_state = 0;
  reg [COUNTER_WIDTH-1:0] baud_counter = 0;
  reg [2:0]    bit_index = 0;
  reg [7:0]    transmit_data = 0;
  reg          transmit_done = 0;
  reg          transmitter_active = 0;
     
  always @(posedge i_Clock)
    begin
       
      case (transmitter_state)
        s_IDLE :
          begin
            o_Tx_Serial   <= 1'b1;         // Drive Line High for Idle
            transmit_done <= 1'b0;
            baud_counter  <= 0;
            bit_index     <= 0;
             
            if (i_Tx_DV == 1'b1)
              begin
                transmitter_active <= 1'b1;
                transmit_data      <= i_Tx_Byte;
                transmitter_state  <= s_TX_START_BIT;
              end
            else
              transmitter_state <= s_IDLE;
          end // case: s_IDLE
         
         
        // Send out Start Bit. Start bit = 0
        s_TX_START_BIT :
          begin
            o_Tx_Serial <= 1'b0;
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (baud_counter < CLKS_PER_BIT-1)
              begin
                baud_counter      <= baud_counter + 1;
                transmitter_state <= s_TX_START_BIT;
              end
            else
              begin
                baud_counter      <= 0;
                transmitter_state <= s_TX_DATA_BITS;
              end
          end // case: s_TX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        s_TX_DATA_BITS :
          begin
            o_Tx_Serial <= transmit_data[bit_index];
             
            if (baud_counter < CLKS_PER_BIT-1)
              begin
                baud_counter      <= baud_counter + 1;
                transmitter_state <= s_TX_DATA_BITS;
              end
            else
              begin
                baud_counter <= 0;
                 
                // Check if we have sent out all bits
                if (bit_index < 7)
                  begin
                    bit_index         <= bit_index + 1;
                    transmitter_state <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    bit_index         <= 0;
                    transmitter_state <= s_TX_STOP_BIT;
                  end
              end
          end // case: s_TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (baud_counter < CLKS_PER_BIT-1)
              begin
                baud_counter      <= baud_counter + 1;
                transmitter_state <= s_TX_STOP_BIT;
              end
            else
              begin
                transmit_done      <= 1'b1;
                baud_counter       <= 0;
                transmitter_state  <= s_CLEANUP;
                transmitter_active <= 1'b0;
              end
          end // case: s_Tx_STOP_BIT
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            transmit_done     <= 1'b1;
            transmitter_state <= s_IDLE;
          end
         
         
        default :
          transmitter_state <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Active = transmitter_active;
  assign o_Tx_Done   = transmit_done;
   
endmodule