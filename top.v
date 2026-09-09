// Francesco DE CANIO - francesco_decanio@hotmail.com
// Top-level wrapper for the Zybo UART loopback design.
 
module top
  (
   input  clk,      // Clock di sistema Zybo, pin L16, 125 MHz
   input  uart_rx_pin, // TXD del CP2102 -> ingresso RX della FPGA
   output uart_tx_pin  // RXD del CP2102 <- uscita TX della FPGA
   );
 
  tx_rx_loopback #(.CLKS_PER_BIT(1085)) LOOPBACK_INST
    (
     .i_Clock   (clk),
     .i_UART_RX (uart_rx_pin),
     .o_UART_TX (uart_tx_pin)
     );
     
     
 
 
endmodule