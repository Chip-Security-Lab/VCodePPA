//SystemVerilog
module mipi_dphy_lp_controller (
  input wire clk, reset_n,
  input wire [1:0] lp_mode,
  input wire enable_lpdt,
  input wire [7:0] lpdt_data,
  output reg [1:0] lp_out,
  output reg lpdt_done
);

  localparam IDLE = 3'd0,
             LPDT_START = 3'd1,
             LPDT_DATA = 3'd2,
             LPDT_STOP = 3'd3;
             
  reg [2:0] state, next_state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  reg bit_count_en, bit_count_rst;
  
  // Karatsuba乘法器模块
  module karatsuba_multiplier #(
    parameter WIDTH = 8
  ) (
    input wire [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] result
  );
    localparam HALF_WIDTH = WIDTH/2;
    
    wire [HALF_WIDTH-1:0] a_high = a[WIDTH-1:HALF_WIDTH];
    wire [HALF_WIDTH-1:0] a_low = a[HALF_WIDTH-1:0];
    wire [HALF_WIDTH-1:0] b_high = b[WIDTH-1:HALF_WIDTH];
    wire [HALF_WIDTH-1:0] b_low = b[HALF_WIDTH-1:0];
    
    wire [2*HALF_WIDTH-1:0] z0, z1, z2;
    wire [HALF_WIDTH-1:0] sum_a = a_high + a_low;
    wire [HALF_WIDTH-1:0] sum_b = b_high + b_low;
    
    karatsuba_multiplier #(HALF_WIDTH) mult_low (a_low, b_low, z0);
    karatsuba_multiplier #(HALF_WIDTH) mult_high (a_high, b_high, z1);
    karatsuba_multiplier #(HALF_WIDTH) mult_mid (sum_a, sum_b, z2);
    
    // 条件反相减法器实现
    wire [2*HALF_WIDTH-1:0] z2_inv = ~z2;
    wire [2*HALF_WIDTH-1:0] z1_inv = ~z1;
    wire [2*HALF_WIDTH-1:0] z0_inv = ~z0;
    
    wire [2*HALF_WIDTH-1:0] z2_sub_z1 = (z2 >= z1) ? (z2 - z1) : (~(z1 - z2) + 1);
    wire [2*HALF_WIDTH-1:0] z2_sub_z0 = (z2 >= z0) ? (z2 - z0) : (~(z0 - z2) + 1);
    wire [2*HALF_WIDTH-1:0] z2_sub = z2_sub_z1 + z2_sub_z0;
    
    always @(*) begin
      result = (z1 << WIDTH) + (z2_sub << HALF_WIDTH) + z0;
    end
  endmodule
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count <= 4'd0;
    end else if (bit_count_rst) begin
      bit_count <= 4'd0;
    end else if (bit_count_en) begin
      bit_count <= bit_count + 1'b1;
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      shift_reg <= 8'd0;
    end else if (state == IDLE && enable_lpdt) begin
      shift_reg <= lpdt_data;
    end else if (state == LPDT_DATA) begin
      shift_reg <= {shift_reg[6:0], 1'b0};
    end
  end
  
  always @(*) begin
    next_state = state;
    lp_out = 2'b11;
    lpdt_done = 1'b0;
    bit_count_en = 1'b0;
    bit_count_rst = 1'b0;
    
    case (state)
      IDLE: begin
        if (lp_mode != 2'b00) 
          lp_out = lp_mode;
        
        if (enable_lpdt) begin
          next_state = LPDT_START;
          bit_count_rst = 1'b1;
        end
      end
      
      LPDT_START: begin
        lp_out = 2'b01;
        next_state = LPDT_DATA;
      end
      
      LPDT_DATA: begin
        lp_out = shift_reg[7] ? 2'b10 : 2'b01;
        bit_count_en = 1'b1;
        
        if (bit_count == 4'd7)
          next_state = LPDT_STOP;
      end
      
      LPDT_STOP: begin
        lp_out = 2'b11;
        lpdt_done = 1'b1;
        next_state = IDLE;
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
  end
endmodule