//SystemVerilog
module mipi_dphy_lp_controller (
  input wire clk, reset_n,
  input wire [1:0] lp_mode,
  input wire enable_lpdt,
  input wire [7:0] lpdt_data,
  output reg [1:0] lp_out,
  output reg lpdt_done
);
  localparam IDLE = 3'd0;
  localparam START = 3'd1;
  localparam DATA = 3'd2;
  localparam STOP = 3'd3;
  
  reg [2:0] state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  
  // Kogge-Stone adder signals
  wire [3:0] g [0:3];
  wire [3:0] p [0:3];
  wire [3:0] next_bit_count;
  
  // Generate and Propagate computation
  assign g[0] = {3'b0, 1'b1};
  assign p[0] = {3'b0, 1'b1};
  
  // First level
  assign g[1][0] = g[0][0];
  assign p[1][0] = p[0][0];
  assign g[1][1] = g[0][1] | (p[0][1] & g[0][0]);
  assign p[1][1] = p[0][1] & p[0][0];
  
  // Second level
  assign g[2][0] = g[1][0];
  assign p[2][0] = p[1][0];
  assign g[2][1] = g[1][1];
  assign p[2][1] = p[1][1];
  assign g[2][2] = g[1][2] | (p[1][2] & g[1][0]);
  assign p[2][2] = p[1][2] & p[1][0];
  assign g[2][3] = g[1][3] | (p[1][3] & g[1][1]);
  assign p[2][3] = p[1][3] & p[1][1];
  
  // Final level
  assign g[3][0] = g[2][0];
  assign p[3][0] = p[2][0];
  assign g[3][1] = g[2][1];
  assign p[3][1] = p[2][1];
  assign g[3][2] = g[2][2];
  assign p[3][2] = p[2][2];
  assign g[3][3] = g[2][3] | (p[2][3] & g[2][1]);
  assign p[3][3] = p[2][3] & p[2][1];
  
  // Sum computation
  assign next_bit_count[0] = bit_count[0] ^ 1'b1;
  assign next_bit_count[1] = bit_count[1] ^ g[3][0];
  assign next_bit_count[2] = bit_count[2] ^ g[3][1];
  assign next_bit_count[3] = bit_count[3] ^ g[3][2];
  
  wire [7:0] next_shift_reg;
  wire [1:0] next_lp_out;
  
  assign next_shift_reg = {shift_reg[6:0], 1'b0};
  assign next_lp_out = shift_reg[7] ? 2'b10 : 2'b01;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      lp_out <= 2'b11;
      lpdt_done <= 1'b0;
      bit_count <= 4'd0;
    end else begin
      case (state)
        IDLE: begin
          if (lp_mode != 2'b00) lp_out <= lp_mode;
          if (enable_lpdt) begin
            state <= START;
            shift_reg <= lpdt_data;
            bit_count <= 4'd0;
          end
        end
        START: begin
          lp_out <= 2'b01;
          state <= DATA;
        end
        DATA: begin
          lp_out <= next_lp_out;
          shift_reg <= next_shift_reg;
          bit_count <= next_bit_count;
          if (bit_count == 4'd7) state <= STOP;
        end
        STOP: begin
          lp_out <= 2'b11;
          lpdt_done <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule