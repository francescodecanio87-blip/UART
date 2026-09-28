// Francesco DE CANIO - francesco_decanio@hotmail.com
// UART loopback: receives bytes from the PC and retransmits them
// through the UART output, preserving one pending byte while TX is busy.

module tx_rx_loopback
  #(parameter CLKS_PER_BIT = 1085)
  (
   input  i_Clock,     // Clock della board (125 MHz su Zybo)
   input  i_UART_RX,   // TXD del CP2102 -> ingresso RX della FPGA
   output o_UART_TX    // RXD del CP2102 <- uscita TX della FPGA
   );

  wire       received_valid;
  wire [7:0] received_byte;
  wire       transmitter_busy;
  wire       transmitter_done;

  reg        transmit_valid = 1'b0;
  reg [7:0]  transmit_byte   = 8'h00;
  reg        pending_valid  = 1'b0;
  reg [7:0]  pending_byte   = 8'h00;

  // Istanzia il ricevitore UART: campiona la linea seriale in ingresso
  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_INST
    (
     .i_Clock     (i_Clock),
     .i_Rx_Serial (i_UART_RX),
    .o_Rx_DV     (received_valid),
    .o_Rx_Byte   (received_byte)
     );

  // Istanzia il trasmettitore UART: rimanda indietro il byte ricevuto
  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_INST
    (
     .i_Clock      (i_Clock),
    .i_Tx_DV      (transmit_valid),
    .i_Tx_Byte    (transmit_byte),
    .o_Tx_Active  (transmitter_busy),
     .o_Tx_Serial  (o_UART_TX),
    .o_Tx_Done    (transmitter_done)
     );

  // Conserva un byte mentre il trasmettitore sta ancora inviando quello
  // precedente, evitando di perdere caratteri consecutivi.
  always @(posedge i_Clock)
    begin
      transmit_valid <= 1'b0;

      if (transmitter_busy == 1'b0)
        begin
          if (pending_valid == 1'b1)
            begin
              transmit_byte  <= pending_byte;
              transmit_valid <= 1'b1;
              pending_valid  <= received_valid;
              if (received_valid == 1'b1)
                pending_byte <= received_byte;
            end
          else if (received_valid == 1'b1)
            begin
              transmit_byte  <= received_byte;
              transmit_valid <= 1'b1;
            end
        end
      else if (received_valid == 1'b1)
        begin
          pending_byte  <= received_byte;
          pending_valid <= 1'b1;
        end
    end

endmodule