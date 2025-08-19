//SystemVerilog
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
  
  reg [31:0] packet_data_buf;
  reg [31:0] packet_data_buf2;
  reg busy_buf;
  reg busy_buf2;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      packet_data <= 32'h0;
      packet_data_buf <= 32'h0;
      packet_data_buf2 <= 32'h0;
      packet_ready <= 1'b0;
      busy <= 1'b0;
      busy_buf <= 1'b0;
      busy_buf2 <= 1'b0;
      param_idx <= 4'd0;
    end else begin
      busy_buf <= busy;
      packet_data_buf <= packet_data;
      busy_buf2 <= busy_buf;
      packet_data_buf2 <= packet_data_buf;
      
      case ({encode_start, busy_buf2})
        2'b10: begin
          busy <= 1'b1;
          packet_data[7:0] <= cmd_type;
          packet_data[15:8] <= 8'h00;
          packet_data[31:16] <= (parameter_count > 0) ? {8'h00, parameter_data[7:0]} : 16'h0000;
          packet_ready <= 1'b1;
          state <= 4'd1;
        end
        2'b01: begin
          packet_ready <= 1'b0;
          if (state == 4'd5) begin
            busy <= 1'b0;
            state <= 4'd0;
          end else begin
            state <= state + 1'b1;
          end
        end
        default: begin
          packet_ready <= packet_ready;
          busy <= busy;
          state <= state;
        end
      endcase
    end
  end
endmodule