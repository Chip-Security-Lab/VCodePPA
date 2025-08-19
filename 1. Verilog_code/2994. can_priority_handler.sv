module can_priority_handler #(
  parameter NUM_BUFFERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] msg_id [0:NUM_BUFFERS-1],
  input wire [NUM_BUFFERS-1:0] buffer_ready,
  output reg [NUM_BUFFERS-1:0] buffer_select,
  output reg transmit_request
);
  reg [10:0] highest_priority_id;
  reg [$clog2(NUM_BUFFERS)-1:0] highest_priority_idx;
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buffer_select <= 0;
      transmit_request <= 0;
    end else begin
      // Find buffer with lowest ID (highest priority)
      highest_priority_id <= 11'h7FF; // Lowest priority
      highest_priority_idx <= 0;
      
      for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
        if (buffer_ready[i] && msg_id[i] < highest_priority_id) begin
          highest_priority_id <= msg_id[i];
          highest_priority_idx <= i;
        end
      end
      
      buffer_select <= (buffer_ready != 0) ? (1 << highest_priority_idx) : 0;
      transmit_request <= (buffer_ready != 0);
    end
  end
endmodule