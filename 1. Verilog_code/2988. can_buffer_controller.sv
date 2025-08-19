module can_buffer_controller #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire rx_done,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  input wire tx_request, tx_done,
  output reg [10:0] tx_id,
  output reg [7:0] tx_data [0:7],
  output reg [3:0] tx_dlc,
  output reg buffer_full, buffer_empty,
  output reg [3:0] buffer_level
);
  reg [10:0] id_buffer [0:BUFFER_DEPTH-1];
  reg [7:0] data_buffer [0:BUFFER_DEPTH-1][0:7];
  reg [3:0] dlc_buffer [0:BUFFER_DEPTH-1];
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr, wr_ptr;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0; wr_ptr <= 0;
      buffer_full <= 0; buffer_empty <= 1;
      buffer_level <= 0;
    end else begin
      if (rx_done && !buffer_full) begin
        // Write to buffer
      end
      
      if (tx_request && !buffer_empty && tx_done) begin
        // Read from buffer
      end
    end
  end
endmodule