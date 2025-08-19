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
  wire [15:0] param_data_mux;

  // Explicit mux for parameter data selection
  assign param_data_mux = (parameter_count > 0) ? {8'h00, parameter_data[7:0]} : 16'h0000;

  // State machine control
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      busy <= 1'b0;
    end else begin
      case ({encode_start, busy})
        2'b10: begin
          busy <= 1'b1;
          state <= 4'd1;
        end
        2'b11: begin
          if (state == 4'd5) begin
            busy <= 1'b0;
            state <= 4'd0;
          end else begin
            state <= state + 1'b1;
          end
        end
        default: begin
          state <= state;
          busy <= busy;
        end
      endcase
    end
  end

  // Packet data generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      packet_data <= 32'h0;
    end else if (encode_start && !busy) begin
      packet_data[7:0] <= cmd_type;
      packet_data[15:8] <= 8'h00;
      packet_data[31:16] <= param_data_mux;
    end
  end

  // Packet ready signal control
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      packet_ready <= 1'b0;
    end else begin
      case ({encode_start, busy})
        2'b10: packet_ready <= 1'b1;
        2'b11: packet_ready <= 1'b0;
        default: packet_ready <= packet_ready;
      endcase
    end
  end

endmodule