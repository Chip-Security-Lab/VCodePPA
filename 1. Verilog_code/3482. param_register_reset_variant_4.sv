//SystemVerilog
module param_register_reset #(
  parameter WIDTH = 16,
  parameter RESET_VALUE = 16'hFFFF,
  parameter NUM_BUFFERS = 4  // Number of buffer registers
)(
  input wire clk, 
  input wire rst_n,
  input wire load,
  input wire [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);
  
  reg [WIDTH-1:0] next_data;
  reg [WIDTH-1:0] next_data_buf [NUM_BUFFERS-1:0];  // Buffer registers for high fan-out signal
  
  always @(*) begin
    next_data = data_out;
    if (load)
      next_data = data_in;
  end
  
  // Fan-out buffering for next_data signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_BUFFERS; i++)
        next_data_buf[i] <= RESET_VALUE;
    end
    else begin
      for (int i = 0; i < NUM_BUFFERS; i++)
        next_data_buf[i] <= next_data;
    end
  end
  
  // Use one of the buffered signals to drive data_out
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= RESET_VALUE;
    else
      data_out <= next_data_buf[0];  // Use the first buffer
  end
endmodule