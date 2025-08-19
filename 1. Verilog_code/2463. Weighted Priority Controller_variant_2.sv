//SystemVerilog
module weighted_priority_intr_ctrl(
  input [7:0] interrupts,
  input [15:0] weights, // 2 bits per interrupt source
  output [2:0] priority_id,
  output valid
);
  // 中间信号定义
  reg [2:0] highest_id;
  reg [1:0] highest_weight;
  reg found;
  
  // 中断源有效信号
  wire [7:0] valid_interrupts;
  // 中断源权重
  wire [1:0] weight_int0, weight_int1, weight_int2, weight_int3;
  wire [1:0] weight_int4, weight_int5, weight_int6, weight_int7;
  
  // 提取每个中断源的权重 - 减少索引计算
  assign weight_int0 = weights[1:0];
  assign weight_int1 = weights[3:2];
  assign weight_int2 = weights[5:4];
  assign weight_int3 = weights[7:6];
  assign weight_int4 = weights[9:8];
  assign weight_int5 = weights[11:10];
  assign weight_int6 = weights[13:12];
  assign weight_int7 = weights[15:14];
  
  // 确定有效的中断信号 - 预处理阶段
  assign valid_interrupts = interrupts;
  
  // 第一阶段：低4位中断处理（0-3）
  reg [2:0] lower_id;
  reg [1:0] lower_weight;
  reg lower_found;
  
  always @(*) begin : process_lower_interrupts
    lower_id = 3'd0;
    lower_weight = 2'd0;
    lower_found = 1'b0;
    
    // 处理中断源0-3，使用条件运算符优化控制流
    lower_id = valid_interrupts[0] && (weight_int0 > lower_weight) ? 3'd0 : lower_id;
    lower_weight = valid_interrupts[0] && (weight_int0 > lower_weight) ? weight_int0 : lower_weight;
    lower_found = valid_interrupts[0] && (weight_int0 > lower_weight) ? 1'b1 : lower_found;
    
    lower_id = valid_interrupts[1] && (weight_int1 > lower_weight) ? 3'd1 : lower_id;
    lower_weight = valid_interrupts[1] && (weight_int1 > lower_weight) ? weight_int1 : lower_weight;
    lower_found = valid_interrupts[1] && (weight_int1 > lower_weight) ? 1'b1 : lower_found;
    
    lower_id = valid_interrupts[2] && (weight_int2 > lower_weight) ? 3'd2 : lower_id;
    lower_weight = valid_interrupts[2] && (weight_int2 > lower_weight) ? weight_int2 : lower_weight;
    lower_found = valid_interrupts[2] && (weight_int2 > lower_weight) ? 1'b1 : lower_found;
    
    lower_id = valid_interrupts[3] && (weight_int3 > lower_weight) ? 3'd3 : lower_id;
    lower_weight = valid_interrupts[3] && (weight_int3 > lower_weight) ? weight_int3 : lower_weight;
    lower_found = valid_interrupts[3] && (weight_int3 > lower_weight) ? 1'b1 : lower_found;
  end
  
  // 第二阶段：高4位中断处理（4-7）
  reg [2:0] upper_id;
  reg [1:0] upper_weight;
  reg upper_found;
  
  always @(*) begin : process_upper_interrupts
    upper_id = 3'd4;
    upper_weight = 2'd0;
    upper_found = 1'b0;
    
    // 处理中断源4-7，使用条件运算符优化控制流
    upper_id = valid_interrupts[4] && (weight_int4 > upper_weight) ? 3'd4 : upper_id;
    upper_weight = valid_interrupts[4] && (weight_int4 > upper_weight) ? weight_int4 : upper_weight;
    upper_found = valid_interrupts[4] && (weight_int4 > upper_weight) ? 1'b1 : upper_found;
    
    upper_id = valid_interrupts[5] && (weight_int5 > upper_weight) ? 3'd5 : upper_id;
    upper_weight = valid_interrupts[5] && (weight_int5 > upper_weight) ? weight_int5 : upper_weight;
    upper_found = valid_interrupts[5] && (weight_int5 > upper_weight) ? 1'b1 : upper_found;
    
    upper_id = valid_interrupts[6] && (weight_int6 > upper_weight) ? 3'd6 : upper_id;
    upper_weight = valid_interrupts[6] && (weight_int6 > upper_weight) ? weight_int6 : upper_weight;
    upper_found = valid_interrupts[6] && (weight_int6 > upper_weight) ? 1'b1 : upper_found;
    
    upper_id = valid_interrupts[7] && (weight_int7 > upper_weight) ? 3'd7 : upper_id;
    upper_weight = valid_interrupts[7] && (weight_int7 > upper_weight) ? weight_int7 : upper_weight;
    upper_found = valid_interrupts[7] && (weight_int7 > upper_weight) ? 1'b1 : upper_found;
  end
  
  // 第三阶段：合并结果，确定最终优先级
  always @(*) begin : determine_final_priority
    // 使用条件运算符合并高低位结果
    highest_id = (upper_found && (!lower_found || upper_weight > lower_weight)) ? upper_id : lower_id;
    highest_weight = (upper_found && (!lower_found || upper_weight > lower_weight)) ? upper_weight : lower_weight;
    found = upper_found || lower_found;
  end
  
  // 输出赋值
  assign priority_id = highest_id;
  assign valid = found;
  
endmodule