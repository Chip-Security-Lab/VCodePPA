//SystemVerilog
`timescale 1ns / 1ps

module can_transmitter(
  input clk, reset_n,
  // Valid-Ready interface input
  input tx_valid,
  output reg tx_ready,
  input [10:0] identifier,
  input [7:0] data_in,
  input [3:0] data_length,
  // Valid-Ready interface output
  output reg tx_valid_out,
  input tx_ready_in,
  output reg can_tx
);
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  reg [3:0] state, next_state;
  reg [7:0] bit_count, data_count;
  reg [14:0] crc;
  reg tx_active, tx_done;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= IDLE;
    else state <= next_state;
  end
  
  always @(*) begin
    case(state)
      IDLE: next_state = (tx_valid && tx_ready) ? SOF : IDLE;
      SOF: next_state = ID;
      // State machine continues with control flow logic
    endcase
  end
  
  // Handle valid-ready handshake for input
  always @(*) begin
    tx_ready = (state == IDLE);
  end
  
  // Handle valid-ready handshake for output
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_valid_out <= 1'b0;
    end else begin
      if (tx_done) begin
        tx_valid_out <= 1'b1;
      end else if (tx_valid_out && tx_ready_in) begin
        tx_valid_out <= 1'b0;
      end
    end
  end
endmodule

module karatsuba_multiplier #(
  parameter WIDTH_A = 15,
  parameter WIDTH_B = 15,
  parameter THRESHOLD = 4
)(
  input clk,
  input reset_n,
  // Valid-Ready interface input
  input valid_in,
  output reg ready_out,
  input [WIDTH_A-1:0] a,
  input [WIDTH_B-1:0] b,
  // Valid-Ready interface output
  output reg valid_out,
  input ready_in,
  output reg [WIDTH_A+WIDTH_B-1:0] result
);
  localparam WIDTH_HIGH_A = WIDTH_A/2 + WIDTH_A%2;
  localparam WIDTH_LOW_A = WIDTH_A/2;
  localparam WIDTH_HIGH_B = WIDTH_B/2 + WIDTH_B%2;
  localparam WIDTH_LOW_B = WIDTH_B/2;
  localparam WIDTH_SUM_A = WIDTH_HIGH_A + 1;
  localparam WIDTH_SUM_B = WIDTH_HIGH_B + 1;
  localparam WIDTH_P1 = WIDTH_HIGH_A + WIDTH_HIGH_B;
  localparam WIDTH_P3 = WIDTH_LOW_A + WIDTH_LOW_B;
  localparam WIDTH_P2_FULL = WIDTH_SUM_A + WIDTH_SUM_B;
  localparam WIDTH_P2 = WIDTH_P1 <= WIDTH_P3 ? WIDTH_P3 : WIDTH_P1;
  
  // 分割输入
  wire [WIDTH_HIGH_A-1:0] a_high;
  wire [WIDTH_LOW_A-1:0] a_low;
  wire [WIDTH_HIGH_B-1:0] b_high;
  wire [WIDTH_LOW_B-1:0] b_low;
  
  assign a_high = a[WIDTH_A-1:WIDTH_LOW_A];
  assign a_low = a[WIDTH_LOW_A-1:0];
  assign b_high = b[WIDTH_B-1:WIDTH_LOW_B];
  assign b_low = b[WIDTH_LOW_B-1:0];
  
  // 中间值
  wire [WIDTH_SUM_A-1:0] a_sum;
  wire [WIDTH_SUM_B-1:0] b_sum;
  wire [WIDTH_P1-1:0] p1;
  wire [WIDTH_P3-1:0] p3;
  wire [WIDTH_P2_FULL-1:0] p2_full;
  wire [WIDTH_P2-1:0] p2;
  
  // 握手控制信号
  reg calc_in_progress;
  reg [1:0] calc_stage;
  wire sub_valid_in;
  wire sub_valid_out;
  wire [2:0] sub_ready_out;
  
  // 计算和
  assign a_sum = a_high + a_low;
  assign b_sum = b_high + b_low;
  
  // 子模块握手协议信号
  assign sub_valid_in = valid_in && ready_out && !calc_in_progress;
  
  // 递归实例化控制
  generate
    if (WIDTH_HIGH_A <= THRESHOLD || WIDTH_HIGH_B <= THRESHOLD) begin: direct_high
      assign p1 = a_high * b_high;
      assign sub_ready_out[0] = 1'b1;
    end else begin: karatsuba_high
      wire high_valid_out;
      wire high_ready_out;
      
      karatsuba_multiplier #(
        .WIDTH_A(WIDTH_HIGH_A),
        .WIDTH_B(WIDTH_HIGH_B),
        .THRESHOLD(THRESHOLD)
      ) high_mult (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(sub_valid_in),
        .ready_out(high_ready_out),
        .a(a_high),
        .b(b_high),
        .valid_out(high_valid_out),
        .ready_in(calc_stage == 2'd1),
        .result(p1)
      );
      
      assign sub_ready_out[0] = high_ready_out;
    end
    
    if (WIDTH_LOW_A <= THRESHOLD || WIDTH_LOW_B <= THRESHOLD) begin: direct_low
      assign p3 = a_low * b_low;
      assign sub_ready_out[1] = 1'b1;
    end else begin: karatsuba_low
      wire low_valid_out;
      wire low_ready_out;
      
      karatsuba_multiplier #(
        .WIDTH_A(WIDTH_LOW_A),
        .WIDTH_B(WIDTH_LOW_B),
        .THRESHOLD(THRESHOLD)
      ) low_mult (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(sub_valid_in),
        .ready_out(low_ready_out),
        .a(a_low),
        .b(b_low),
        .valid_out(low_valid_out),
        .ready_in(calc_stage == 2'd1),
        .result(p3)
      );
      
      assign sub_ready_out[1] = low_ready_out;
    end
    
    if (WIDTH_SUM_A <= THRESHOLD || WIDTH_SUM_B <= THRESHOLD) begin: direct_mid
      assign p2_full = a_sum * b_sum;
      assign sub_ready_out[2] = 1'b1;
    end else begin: karatsuba_mid
      wire mid_valid_out;
      wire mid_ready_out;
      
      karatsuba_multiplier #(
        .WIDTH_A(WIDTH_SUM_A),
        .WIDTH_B(WIDTH_SUM_B),
        .THRESHOLD(THRESHOLD)
      ) mid_mult (
        .clk(clk),
        .reset_n(reset_n),
        .valid_in(sub_valid_in),
        .ready_out(mid_ready_out),
        .a(a_sum),
        .b(b_sum),
        .valid_out(mid_valid_out),
        .ready_in(calc_stage == 2'd1),
        .result(p2_full)
      );
      
      assign sub_ready_out[2] = mid_ready_out;
    end
  endgenerate
  
  // 计算p2 = (a_high + a_low) * (b_high + b_low) - p1 - p3
  wire [WIDTH_P2_FULL-1:0] p1_ext, p3_ext;
  assign p1_ext = {{(WIDTH_P2_FULL-WIDTH_P1){1'b0}}, p1};
  assign p3_ext = {{(WIDTH_P2_FULL-WIDTH_P3){1'b0}}, p3};
  
  wire [WIDTH_P2_FULL-1:0] p2_temp;
  assign p2_temp = p2_full - p1_ext - p3_ext;
  assign p2 = p2_temp[WIDTH_P2-1:0];
  
  // 结果组合
  reg [WIDTH_A+WIDTH_B-1:0] next_result;
  
  always @(*) begin
    next_result = {p1, {WIDTH_LOW_A+WIDTH_LOW_B{1'b0}}} + 
                 {{WIDTH_LOW_A{1'b0}}, p2, {WIDTH_LOW_B{1'b0}}} + 
                 {{WIDTH_HIGH_A+WIDTH_HIGH_B{1'b0}}, p3};
  end
  
  // 握手协议状态机
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      calc_in_progress <= 1'b0;
      calc_stage <= 2'd0;
      valid_out <= 1'b0;
      result <= {(WIDTH_A+WIDTH_B){1'b0}};
    end else begin
      case (calc_stage)
        2'd0: begin // Idle/Ready stage
          if (valid_in && ready_out && !calc_in_progress) begin
            calc_in_progress <= 1'b1;
            calc_stage <= 2'd1;
          end
          
          if (valid_out && ready_in) begin
            valid_out <= 1'b0;
          end
        end
        
        2'd1: begin // Calculation stage
          calc_stage <= 2'd2;
        end
        
        2'd2: begin // Result generation stage
          result <= next_result;
          valid_out <= 1'b1;
          calc_in_progress <= 1'b0;
          calc_stage <= 2'd0;
        end
        
        default: calc_stage <= 2'd0;
      endcase
    end
  end
  
  // Control ready_out signal
  always @(*) begin
    ready_out = !calc_in_progress && &sub_ready_out;
  end
endmodule

module karatsuba_multiplier_15bit(
  input clk,
  input reset_n,
  // Valid-Ready interface input
  input valid_in,
  output ready_out,
  input [14:0] a,
  input [14:0] b,
  // Valid-Ready interface output
  output valid_out,
  input ready_in,
  output [29:0] result
);
  karatsuba_multiplier #(
    .WIDTH_A(15),
    .WIDTH_B(15),
    .THRESHOLD(4)
  ) k_mult (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .a(a),
    .b(b),
    .valid_out(valid_out),
    .ready_in(ready_in),
    .result(result)
  );
endmodule

module karatsuba_multiplier_9bit(
  input clk,
  input reset_n,
  // Valid-Ready interface input
  input valid_in,
  output ready_out,
  input [8:0] a,
  input [8:0] b,
  // Valid-Ready interface output
  output valid_out,
  input ready_in,
  output [17:0] result
);
  karatsuba_multiplier #(
    .WIDTH_A(9),
    .WIDTH_B(9),
    .THRESHOLD(4)
  ) k_mult (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .a(a),
    .b(b),
    .valid_out(valid_out),
    .ready_in(ready_in),
    .result(result)
  );
endmodule

module karatsuba_multiplier_8bit(
  input clk,
  input reset_n,
  // Valid-Ready interface input
  input valid_in,
  output ready_out,
  input [7:0] a,
  input [7:0] b,
  // Valid-Ready interface output
  output valid_out,
  input ready_in,
  output [15:0] result
);
  karatsuba_multiplier #(
    .WIDTH_A(8),
    .WIDTH_B(8),
    .THRESHOLD(4)
  ) k_mult (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .a(a),
    .b(b),
    .valid_out(valid_out),
    .ready_in(ready_in),
    .result(result)
  );
endmodule

module karatsuba_multiplier_7bit(
  input clk,
  input reset_n,
  // Valid-Ready interface input
  input valid_in,
  output ready_out,
  input [6:0] a,
  input [6:0] b,
  // Valid-Ready interface output
  output valid_out,
  input ready_in,
  output [13:0] result
);
  karatsuba_multiplier #(
    .WIDTH_A(7),
    .WIDTH_B(7),
    .THRESHOLD(4)
  ) k_mult (
    .clk(clk),
    .reset_n(reset_n),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .a(a),
    .b(b),
    .valid_out(valid_out),
    .ready_in(ready_in),
    .result(result)
  );
endmodule