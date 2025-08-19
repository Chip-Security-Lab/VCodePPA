module can_data_handler #(
  parameter DATA_WIDTH = 8,
  parameter BUFFER_DEPTH = 4
)(
  input wire clk, rst_n,
  input wire [DATA_WIDTH-1:0] tx_data,
  input wire tx_valid,
  output wire tx_ready,
  input wire [10:0] msg_id,
  output reg [DATA_WIDTH-1:0] rx_data,
  output reg rx_valid,
  input wire rx_ready
);
  reg [DATA_WIDTH-1:0] tx_buffer [0:BUFFER_DEPTH-1];
  reg [$clog2(BUFFER_DEPTH):0] tx_count, tx_rd_ptr, tx_wr_ptr;
  
  assign tx_ready = (tx_count < BUFFER_DEPTH);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_count <= 0; tx_rd_ptr <= 0; tx_wr_ptr <= 0;
    end else if (tx_valid && tx_ready) begin
      tx_buffer[tx_wr_ptr] <= tx_data;
      tx_wr_ptr <= (tx_wr_ptr + 1) % BUFFER_DEPTH;
      tx_count <= tx_count + 1;
    end
  end
endmodule