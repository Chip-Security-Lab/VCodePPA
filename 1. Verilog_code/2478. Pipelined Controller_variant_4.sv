//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module pipelined_intr_ctrl(
  input clk, rst_n,
  input [15:0] intr_req,
  input [15:0] multiplicand, multiplier,
  output reg [3:0] intr_id,
  output reg req,          // 改为req信号，替代原来的valid
  input ack,               // 新增ack信号，替代原来的ready
  output reg [31:0] product
);
  // Pipeline registers - extended to more stages
  reg [15:0] stage1_req;
  reg [15:0] stage2_req;
  reg [3:0] stage3_id_high, stage3_id_low;
  reg stage3_valid_high, stage3_valid_low;
  reg [3:0] stage4_id;
  reg stage4_valid;
  reg [3:0] stage5_id;
  reg stage5_valid;
  
  // Karatsuba乘法相关信号 - extended pipeline
  reg [15:0] a_stage1, b_stage1;
  reg [15:0] a_stage2, b_stage2;
  reg [15:0] a_stage3, b_stage3;
  wire [31:0] mult_result;
  reg [31:0] mult_result_stage1;
  reg [31:0] mult_result_stage2;
  
  // 握手协议状态机相关信号
  reg req_state;        // 请求状态寄存器
  reg ready_for_next;   // 指示可以处理下一个数据
  
  // Karatsuba乘法器实例 - unchanged
  karatsuba_multiplier #(
    .WIDTH(16)
  ) karatsuba_mult_inst (
    .a(a_stage3),
    .b(b_stage3),
    .product(mult_result)
  );
  
  // 请求-应答握手协议状态机
  localparam IDLE = 1'b0,
             REQ_SENT = 1'b1;
             
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_state <= IDLE;
      ready_for_next <= 1'b1;
    end else begin
      case (req_state)
        IDLE: begin
          if (stage5_valid && ready_for_next) begin
            req_state <= REQ_SENT;
            ready_for_next <= 1'b0;
          end
        end
        
        REQ_SENT: begin
          if (ack) begin
            req_state <= IDLE;
            ready_for_next <= 1'b1;
          end
        end
      endcase
    end
  end
  
  // 输出req信号逻辑 - 替代原来的valid输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req <= 1'b0;
      intr_id <= 4'h0;
    end else begin
      case (req_state)
        IDLE: begin
          if (stage5_valid && ready_for_next) begin
            req <= 1'b1;
            intr_id <= stage5_id;
          end
        end
        
        REQ_SENT: begin
          if (ack) begin
            req <= 1'b0;
          end
        end
      endcase
    end
  end
  
  // 乘法输入流水线 - 现在受握手协议控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_stage1 <= 16'h0;
      b_stage1 <= 16'h0;
      a_stage2 <= 16'h0;
      b_stage2 <= 16'h0;
      a_stage3 <= 16'h0;
      b_stage3 <= 16'h0;
    end else if (ready_for_next || (req_state == REQ_SENT && ack)) begin
      // 只有在握手完成或准备好时才更新流水线
      a_stage1 <= multiplicand;
      b_stage1 <= multiplier;
      a_stage2 <= a_stage1;
      b_stage2 <= b_stage1;
      a_stage3 <= a_stage2;
      b_stage3 <= b_stage2;
    end
  end
  
  // 乘法结果流水线 - 受握手协议控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mult_result_stage1 <= 32'h0;
      mult_result_stage2 <= 32'h0;
      product <= 32'h0;
    end else if (ready_for_next || (req_state == REQ_SENT && ack)) begin
      // 只有在握手完成或准备好时才更新结果
      mult_result_stage1 <= mult_result;
      mult_result_stage2 <= mult_result_stage1;
      product <= mult_result_stage2;
    end
  end
  
  // Pipeline stage 1: detect requests - 根据握手状态控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage1_req <= 16'h0;
    else if (ready_for_next || (req_state == REQ_SENT && ack))
      stage1_req <= intr_req;
  end
  
  // Pipeline stage 2: latch and prepare for encoding - 根据握手状态控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      stage2_req <= 16'h0;
    else if (ready_for_next || (req_state == REQ_SENT && ack))
      stage2_req <= stage1_req;
  end
  
  // Pipeline stage 3: split priority encoding into high and low parts - 根据握手状态控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage3_id_high <= 4'h0;
      stage3_valid_high <= 1'b0;
      stage3_id_low <= 4'h0;
      stage3_valid_low <= 1'b0;
    end else if (ready_for_next || (req_state == REQ_SENT && ack)) begin
      // High priority (15-8)
      if (stage2_req[15]) begin
        stage3_id_high <= 4'd15;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[14]) begin
        stage3_id_high <= 4'd14;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[13]) begin
        stage3_id_high <= 4'd13;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[12]) begin
        stage3_id_high <= 4'd12;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[11]) begin
        stage3_id_high <= 4'd11;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[10]) begin
        stage3_id_high <= 4'd10;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[9]) begin
        stage3_id_high <= 4'd9;
        stage3_valid_high <= 1'b1;
      end else if (stage2_req[8]) begin
        stage3_id_high <= 4'd8;
        stage3_valid_high <= 1'b1;
      end else begin
        stage3_id_high <= 4'd0;
        stage3_valid_high <= 1'b0;
      end
      
      // Low priority (7-0)
      if (stage2_req[7]) begin
        stage3_id_low <= 4'd7;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[6]) begin
        stage3_id_low <= 4'd6;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[5]) begin
        stage3_id_low <= 4'd5;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[4]) begin
        stage3_id_low <= 4'd4;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[3]) begin
        stage3_id_low <= 4'd3;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[2]) begin
        stage3_id_low <= 4'd2;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[1]) begin
        stage3_id_low <= 4'd1;
        stage3_valid_low <= 1'b1;
      end else if (stage2_req[0]) begin
        stage3_id_low <= 4'd0;
        stage3_valid_low <= 1'b1;
      end else begin
        stage3_id_low <= 4'd0;
        stage3_valid_low <= 1'b0;
      end
    end
  end
  
  // Pipeline stage 4: merge high and low priority results - 根据握手状态控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage4_id <= 4'h0;
      stage4_valid <= 1'b0;
    end else if (ready_for_next || (req_state == REQ_SENT && ack)) begin
      if (stage3_valid_high) begin
        stage4_id <= stage3_id_high;
        stage4_valid <= 1'b1;
      end else if (stage3_valid_low) begin
        stage4_id <= stage3_id_low;
        stage4_valid <= 1'b1;
      end else begin
        stage4_id <= 4'h0;
        stage4_valid <= 1'b0;
      end
    end
  end
  
  // Pipeline stage 5: buffer result before final output - 根据握手状态控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage5_id <= 4'h0;
      stage5_valid <= 1'b0;
    end else if (ready_for_next || (req_state == REQ_SENT && ack)) begin
      stage5_id <= stage4_id;
      stage5_valid <= stage4_valid;
    end
  end
endmodule

// 递归Karatsuba乘法器模块 - unchanged
module karatsuba_multiplier #(
  parameter WIDTH = 16
)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output [2*WIDTH-1:0] product
);
  generate
    if (WIDTH <= 4) begin: small_mult
      // 对于小位宽，直接使用常规乘法
      assign product = a * b;
    end else begin: karatsuba_recursion
      localparam HALF_WIDTH = WIDTH / 2;
      
      // 分割输入为高低两部分
      wire [HALF_WIDTH-1:0] a_low, b_low;
      wire [HALF_WIDTH-1:0] a_high, b_high;
      
      assign a_low = a[HALF_WIDTH-1:0];
      assign a_high = a[WIDTH-1:HALF_WIDTH];
      assign b_low = b[HALF_WIDTH-1:0];
      assign b_high = b[WIDTH-1:HALF_WIDTH];
      
      // 中间项计算
      wire [HALF_WIDTH-1:0] a_sum, b_sum;
      assign a_sum = a_low + a_high;
      assign b_sum = b_low + b_high;
      
      // 递归计算三个子乘积
      wire [2*HALF_WIDTH-1:0] p1; // a_high * b_high
      wire [2*HALF_WIDTH-1:0] p2; // a_low * b_low
      wire [2*HALF_WIDTH-1:0] p3; // (a_high + a_low) * (b_high + b_low)
      
      karatsuba_multiplier #(
        .WIDTH(HALF_WIDTH)
      ) high_mult (
        .a(a_high),
        .b(b_high),
        .product(p1)
      );
      
      karatsuba_multiplier #(
        .WIDTH(HALF_WIDTH)
      ) low_mult (
        .a(a_low),
        .b(b_low),
        .product(p2)
      );
      
      karatsuba_multiplier #(
        .WIDTH(HALF_WIDTH)
      ) mid_mult (
        .a(a_sum),
        .b(b_sum),
        .product(p3)
      );
      
      // Karatsuba算法最终计算
      wire [2*WIDTH-1:0] term1, term2, term3;
      wire [2*WIDTH-1:0] middle_term;
      
      assign term1 = {{HALF_WIDTH{1'b0}}, p2};
      assign term3 = {p1, {HALF_WIDTH{1'b0}}};
      assign middle_term = p3 - p1 - p2;
      assign term2 = {middle_term, {HALF_WIDTH{1'b0}}} >> HALF_WIDTH;
      
      // 最终结果
      assign product = term1 + term2 + term3;
    end
  endgenerate
endmodule