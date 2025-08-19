//SystemVerilog
//IEEE 1364-2005

// 顶层模块
module weighted_priority_intr_ctrl(
  input [7:0] interrupts,
  input [15:0] weights, // 2 bits per interrupt source
  output [2:0] priority_id,
  output valid
);
  // 用于保存每个中断源的权重
  wire [1:0] weight_array [0:7];
  // 权重比较的结果
  wire [7:0] is_highest;
  // 用于编码高优先级ID
  wire [2:0] encoded_id;
  wire interrupt_found;

  // 提取各个中断权重到数组
  weight_extractor weight_ext_inst (
    .weights(weights),
    .weight_array(weight_array)
  );

  // 比较各中断源的权重并找出最高优先级
  priority_comparator pri_comp_inst (
    .interrupts(interrupts),
    .weight_array(weight_array),
    .is_highest(is_highest),
    .valid(interrupt_found)
  );

  // 将最高优先级的中断编码为ID
  priority_encoder pri_enc_inst (
    .is_highest(is_highest),
    .priority_id(encoded_id)
  );

  // 连接输出
  assign priority_id = encoded_id;
  assign valid = interrupt_found;
endmodule

// 子模块：提取权重信息
module weight_extractor (
  input [15:0] weights,
  output [1:0] weight_array [0:7]
);
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : weight_extract
      assign weight_array[i] = weights[i*2+:2];
    end
  endgenerate
endmodule

// 子模块：比较所有中断源的优先级
module priority_comparator (
  input [7:0] interrupts,
  input [1:0] weight_array [0:7],
  output [7:0] is_highest,
  output valid
);
  reg [7:0] highest_flags;
  reg [1:0] highest_weight;
  reg found;
  
  integer i;
  
  always @(*) begin
    highest_flags = 8'd0;
    highest_weight = 2'd0;
    found = 1'b0;
    
    // 第一遍扫描找出最高权重
    for (i = 0; i < 8; i = i + 1) begin
      if (interrupts[i] && (weight_array[i] > highest_weight)) begin
        highest_weight = weight_array[i];
        found = 1'b1;
      end
    end
    
    // 第二遍扫描标记具有最高权重的中断
    for (i = 0; i < 8; i = i + 1) begin
      if (interrupts[i] && (weight_array[i] == highest_weight)) begin
        highest_flags[i] = 1'b1;
      end
    end
  end
  
  assign is_highest = highest_flags;
  assign valid = found;
endmodule

// 子模块：将最高优先级标志编码为ID
module priority_encoder (
  input [7:0] is_highest,
  output reg [2:0] priority_id
);
  always @(*) begin
    priority_id = 3'd0;
    
    // 优先选择最低索引的高优先级中断
    if (is_highest[0]) priority_id = 3'd0;
    else if (is_highest[1]) priority_id = 3'd1;
    else if (is_highest[2]) priority_id = 3'd2;
    else if (is_highest[3]) priority_id = 3'd3;
    else if (is_highest[4]) priority_id = 3'd4;
    else if (is_highest[5]) priority_id = 3'd5;
    else if (is_highest[6]) priority_id = 3'd6;
    else if (is_highest[7]) priority_id = 3'd7;
  end
endmodule