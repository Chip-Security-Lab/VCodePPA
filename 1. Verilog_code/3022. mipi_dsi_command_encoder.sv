module mipi_dsi_command_encoder (
  input wire clk, reset_n,
  input wire [7:0] cmd_type,
  input wire [15:0] parameter_data,
  input wire [3:0] parameter_count,
  input wire encode_start,
  output reg [31:0] packet_data,
  output reg packet_ready,
  output reg busy
);
  reg [3:0] state;
  reg [3:0] param_idx;
  reg [7:0] ecc;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      packet_data <= 32'h0;
      packet_ready <= 1'b0;
      busy <= 1'b0;
      param_idx <= 4'd0;
    end else if (encode_start && !busy) begin
      busy <= 1'b1;
      packet_data[7:0] <= cmd_type;
      packet_data[15:8] <= 8'h00; // Virtual channel
      packet_data[31:16] <= (parameter_count > 0) ? {8'h00, parameter_data[7:0]} : 16'h0000;
      packet_ready <= 1'b1;
      state <= 4'd1;
    end else if (busy) begin /* State machine continues */
      packet_ready <= 1'b0;
      if (state == 4'd5) begin busy <= 1'b0; state <= 4'd0; end
      else state <= state + 1'b1;
    end
  end
endmodule