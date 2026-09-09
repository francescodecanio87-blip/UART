// Francesco DE CANIO - francesco_decanio@hotmail.com
// UART receiver: samples an asynchronous serial input and outputs
// one valid pulse together with each received 8-bit data word.

module uart_rx 
  #(parameter CLKS_PER_BIT = 1085)
  (
   input        i_Clock,
   input        i_Rx_Serial,
   output       o_Rx_DV,
   output [7:0] o_Rx_Byte
   );

  localparam integer COUNTER_WIDTH = $clog2(CLKS_PER_BIT);
    
  parameter s_IDLE         = 3'b000;
  parameter s_RX_START_BIT = 3'b001;
  parameter s_RX_DATA_BITS = 3'b010;
  parameter s_RX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  (* ASYNC_REG = "TRUE" *) reg sync_stage1 = 1'b1;
  (* ASYNC_REG = "TRUE" *) reg sync_stage2 = 1'b1;
   
  reg [COUNTER_WIDTH-1:0] baud_counter = 0;
  reg [2:0]     bit_index      = 0;
  reg [7:0]     received_byte  = 0;
  reg           received_valid = 0;
  reg [2:0]     receiver_state = 0;
   
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      sync_stage1 <= i_Rx_Serial;
      sync_stage2 <= sync_stage1;
    end
   
   
  // Purpose: Control RX state machine
  always @(posedge i_Clock)
    begin
       
      case (receiver_state)
        s_IDLE :
          begin
            received_valid <= 1'b0;
            baud_counter   <= 0;
            bit_index      <= 0;
             
            if (sync_stage2 == 1'b0)
              receiver_state <= s_RX_START_BIT;
            else
              receiver_state <= s_IDLE;
          end
         
        // Check middle of start bit to make sure it's still low
        s_RX_START_BIT :
          begin
            if (baud_counter == (CLKS_PER_BIT-1)/2)
              begin
                if (sync_stage2 == 1'b0)
                  begin
                    baud_counter   <= 0;
                    receiver_state <= s_RX_DATA_BITS;
                  end
                else
                  receiver_state <= s_IDLE;
              end
            else
              begin
                baud_counter   <= baud_counter + 1;
                receiver_state <= s_RX_START_BIT;
              end
          end // case: s_RX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        s_RX_DATA_BITS :
          begin
            if (baud_counter < CLKS_PER_BIT-1)
              begin
                baud_counter   <= baud_counter + 1;
                receiver_state <= s_RX_DATA_BITS;
              end
            else
              begin
                baud_counter             <= 0;
                received_byte[bit_index] <= sync_stage2;
                 
                // Check if we have received all bits
                if (bit_index < 7)
                  begin
                    bit_index      <= bit_index + 1;
                    receiver_state <= s_RX_DATA_BITS;
                  end
                else
                  begin
                    bit_index      <= 0;
                    receiver_state <= s_RX_STOP_BIT;
                  end
              end
          end // case: s_RX_DATA_BITS
     
     
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BIT :
          begin
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (baud_counter < CLKS_PER_BIT-1)
              begin
                baud_counter   <= baud_counter + 1;
                receiver_state <= s_RX_STOP_BIT;
              end
            else
              begin
                received_valid <= 1'b1;
                baud_counter   <= 0;
                receiver_state <= s_CLEANUP;
              end
          end // case: s_RX_STOP_BIT
     
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            receiver_state <= s_IDLE;
            received_valid <= 1'b0;
          end
         
         
        default :
          receiver_state <= s_IDLE;
         
      endcase
    end   
   
  assign o_Rx_DV   = received_valid;
  assign o_Rx_Byte = received_byte;
   
endmodule // uart_rx