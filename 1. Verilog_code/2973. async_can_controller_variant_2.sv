//SystemVerilog
module async_can_controller(
  input wire clk, reset, rx,
  input wire [10:0] tx_id,
  input wire [63:0] tx_data,
  input wire [3:0] tx_len,
  input wire tx_request,
  output reg tx,
  output wire tx_busy, rx_ready,
  output reg [10:0] rx_id,
  output reg [63:0] rx_data,
  output reg [3:0] rx_len
);
  
  // IEEE 1364-2005 Verilog standard
  
  reg [2:0] bit_phase;
  reg [6:0] bit_position; // Increased width for better range handling
  reg [87:0] tx_frame; // Max frame size
  
  // Use direct comparison for busy signal
  assign tx_busy = |bit_position;
  
  // Optimized output mux
  always @(*) begin
    tx = |bit_position ? tx_frame[bit_position-1] : 1'b1;
  end
  
  // Improved frame handling and reset
  always @(posedge clk) begin
    if (reset) begin
      bit_position <= 7'b0;
    end 
    else if (tx_request && !tx_busy) begin
      // Pack frame more efficiently
      tx_frame <= {tx_id, tx_len, tx_data};
      bit_position <= 7'd87; // Use explicit width for constants
    end
    else if (|bit_position) begin
      bit_position <= bit_position - 7'd1;
    end
  end
  
  // Default assignment for rx_ready
  assign rx_ready = 1'b0;
  
endmodule