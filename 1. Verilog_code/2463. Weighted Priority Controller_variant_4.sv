//SystemVerilog
//IEEE 1364-2005
module weighted_priority_intr_ctrl(
  input [7:0] interrupts,
  input [15:0] weights, // 2 bits per interrupt source
  input ack,           // 新增的应答输入信号
  output [2:0] priority_id,
  output reg req       // 替换valid为req请求信号
);
  wire [1:0] w0 = weights[1:0];
  wire [1:0] w1 = weights[3:2];
  wire [1:0] w2 = weights[5:4];
  wire [1:0] w3 = weights[7:6];
  wire [1:0] w4 = weights[9:8];
  wire [1:0] w5 = weights[11:10];
  wire [1:0] w6 = weights[13:12];
  wire [1:0] w7 = weights[15:14];
  
  // Weighted interrupts
  wire [7:0] active_int;
  wire [1:0] active_weights [0:7];
  
  // Calculate active interrupts and their weights
  assign active_int = interrupts; // 简化赋值
  
  // 使用生成块简化代码
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin: gen_weights
      assign active_weights[i] = active_int[i] ? weights[i*2+1:i*2] : 2'b00;
    end
  endgenerate
  
  // Priority resolution using LUT approach
  // For each bit position in priority_id, determine when it should be 1
  wire [2:0] result_id;
  wire result_valid;
  
  // Bit 2 (MSB) of priority_id
  wire bit2_from_4 = active_weights[4] > active_weights[0] && active_weights[4] > active_weights[1] && 
                     active_weights[4] > active_weights[2] && active_weights[4] > active_weights[3];
  wire bit2_from_5 = active_weights[5] > active_weights[0] && active_weights[5] > active_weights[1] && 
                     active_weights[5] > active_weights[2] && active_weights[5] > active_weights[3];
  wire bit2_from_6 = active_weights[6] > active_weights[0] && active_weights[6] > active_weights[1] && 
                     active_weights[6] > active_weights[2] && active_weights[6] > active_weights[3];
  wire bit2_from_7 = active_weights[7] > active_weights[0] && active_weights[7] > active_weights[1] && 
                     active_weights[7] > active_weights[2] && active_weights[7] > active_weights[3];
  
  wire bit2 = bit2_from_4 || bit2_from_5 || bit2_from_6 || bit2_from_7;
  
  // Bit 1 of priority_id
  wire bit1_from_2 = !bit2 && (active_weights[2] > active_weights[0] && active_weights[2] > active_weights[1]);
  wire bit1_from_3 = !bit2 && (active_weights[3] > active_weights[0] && active_weights[3] > active_weights[1]);
  wire bit1_from_6 = bit2 && (active_weights[6] > active_weights[4] && active_weights[6] > active_weights[5] && 
                     active_weights[6] > active_weights[7]);
  wire bit1_from_7 = bit2 && (active_weights[7] > active_weights[4] && active_weights[7] > active_weights[5] && 
                     active_weights[7] > active_weights[6]);
  
  wire bit1 = bit1_from_2 || bit1_from_3 || bit1_from_6 || bit1_from_7;
  
  // Bit 0 (LSB) of priority_id
  wire bit0_from_1 = !bit2 && !bit1 && (active_weights[1] > active_weights[0]);
  wire bit0_from_3 = !bit2 && bit1_from_2 && (active_weights[3] > active_weights[2]);
  wire bit0_from_5 = bit2 && !bit1 && (active_weights[5] > active_weights[4]);
  wire bit0_from_7 = bit2 && bit1_from_6 && (active_weights[7] > active_weights[6]);
  
  wire bit0 = bit0_from_1 || bit0_from_3 || bit0_from_5 || bit0_from_7;
  
  // Combine bits to form final priority_id
  assign result_id = {bit2, bit1, bit0};
  
  // Valid output if any interrupt is active with non-zero weight
  wire any_valid_weight = |{active_weights[0], active_weights[1], active_weights[2], active_weights[3],
                           active_weights[4], active_weights[5], active_weights[6], active_weights[7]};
  assign result_valid = (|active_int) && any_valid_weight;
  
  // 实现Req-Ack握手协议的状态
  reg req_pending;
  
  // Req-Ack握手逻辑
  always @(posedge result_valid or posedge ack) begin
    if (ack) begin
      // 收到应答信号，清除请求
      req <= 1'b0;
      req_pending <= 1'b0;
    end else if (result_valid && !req_pending) begin
      // 有新的有效中断且当前没有挂起的请求
      req <= 1'b1;
      req_pending <= 1'b1;
    end
  end
  
  // Final outputs
  assign priority_id = result_id;
endmodule