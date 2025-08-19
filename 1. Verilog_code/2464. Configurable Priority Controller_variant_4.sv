//SystemVerilog
`timescale 1ns / 1ps
module config_priority_intr_ctrl(
  input clk, async_rst_n, sync_rst,
  input [15:0] intr_sources,
  input [15:0] intr_mask,
  input [63:0] priority_config, // 4 bits per interrupt
  input intr_ack, // 新增，替代ready信号
  output reg [3:0] intr_id,
  output reg intr_req // 修改，替代valid/intr_active信号
);
  reg [15:0] masked_src;
  reg req_pending; // 用于跟踪请求状态
  
  // 跳跃进位加法器信号声明
  wire [3:0] priority_values[0:15];
  wire [15:0] valid_intr;
  wire [3:0] level1_priority[0:7];
  wire [3:0] level1_id[0:7];
  wire [7:0] level1_valid;
  wire [3:0] level2_priority[0:3];
  wire [3:0] level2_id[0:3];
  wire [3:0] level2_valid;
  wire [3:0] level3_priority[0:1];
  wire [3:0] level3_id[0:1];
  wire [1:0] level3_valid;
  wire [3:0] final_priority;
  wire [3:0] final_id;
  wire final_valid;
  
  // 解析每个中断的优先级
  generate
    genvar g;
    for (g = 0; g < 16; g = g + 1) begin: gen_priority
      assign priority_values[g] = priority_config[g*4+:4];
      assign valid_intr[g] = masked_src[g];
    end
  endgenerate
  
  // 第一级比较（8组，每组2个中断）
  generate
    for (g = 0; g < 8; g = g + 1) begin: level1_compare
      assign level1_valid[g] = valid_intr[g*2] | valid_intr[g*2+1];
      assign level1_priority[g] = (!valid_intr[g*2]) ? priority_values[g*2+1] :
                                 (!valid_intr[g*2+1]) ? priority_values[g*2] :
                                 (priority_values[g*2] < priority_values[g*2+1]) ? 
                                  priority_values[g*2] : priority_values[g*2+1];
      assign level1_id[g] = (!valid_intr[g*2]) ? (g*2+1) :
                           (!valid_intr[g*2+1]) ? (g*2) :
                           (priority_values[g*2] < priority_values[g*2+1]) ? 
                            (g*2) : (g*2+1);
    end
  endgenerate
  
  // 第二级比较（4组，每组2个来自第一级）
  generate
    for (g = 0; g < 4; g = g + 1) begin: level2_compare
      assign level2_valid[g] = level1_valid[g*2] | level1_valid[g*2+1];
      assign level2_priority[g] = (!level1_valid[g*2]) ? level1_priority[g*2+1] :
                                 (!level1_valid[g*2+1]) ? level1_priority[g*2] :
                                 (level1_priority[g*2] < level1_priority[g*2+1]) ? 
                                  level1_priority[g*2] : level1_priority[g*2+1];
      assign level2_id[g] = (!level1_valid[g*2]) ? level1_id[g*2+1] :
                           (!level1_valid[g*2+1]) ? level1_id[g*2] :
                           (level1_priority[g*2] < level1_priority[g*2+1]) ? 
                            level1_id[g*2] : level1_id[g*2+1];
    end
  endgenerate
  
  // 第三级比较（2组，每组2个来自第二级）
  generate
    for (g = 0; g < 2; g = g + 1) begin: level3_compare
      assign level3_valid[g] = level2_valid[g*2] | level2_valid[g*2+1];
      assign level3_priority[g] = (!level2_valid[g*2]) ? level2_priority[g*2+1] :
                                 (!level2_valid[g*2+1]) ? level2_priority[g*2] :
                                 (level2_priority[g*2] < level2_priority[g*2+1]) ? 
                                  level2_priority[g*2] : level2_priority[g*2+1];
      assign level3_id[g] = (!level2_valid[g*2]) ? level2_id[g*2+1] :
                           (!level2_valid[g*2+1]) ? level2_id[g*2] :
                           (level2_priority[g*2] < level2_priority[g*2+1]) ? 
                            level2_id[g*2] : level2_id[g*2+1];
    end
  endgenerate
  
  // 最终比较
  assign final_valid = level3_valid[0] | level3_valid[1];
  assign final_priority = (!level3_valid[0]) ? level3_priority[1] :
                         (!level3_valid[1]) ? level3_priority[0] :
                         (level3_priority[0] < level3_priority[1]) ? 
                          level3_priority[0] : level3_priority[1];
  assign final_id = (!level3_valid[0]) ? level3_id[1] :
                   (!level3_valid[1]) ? level3_id[0] :
                   (level3_priority[0] < level3_priority[1]) ? 
                    level3_id[0] : level3_id[1];
  
  // 请求-应答握手逻辑
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      intr_id <= 4'd0;
      intr_req <= 1'b0;
      masked_src <= 16'h0;
      req_pending <= 1'b0;
    end else if (sync_rst) begin
      intr_id <= 4'd0;
      intr_req <= 1'b0;
      masked_src <= 16'h0;
      req_pending <= 1'b0;
    end else begin
      masked_src <= intr_sources & intr_mask;
      
      // 请求-应答逻辑
      if (intr_req && intr_ack) begin
        // 请求被确认，清除请求
        intr_req <= 1'b0;
        req_pending <= 1'b0;
      end else if (!intr_req && final_valid && !req_pending) begin
        // 有新中断，发送请求
        intr_req <= 1'b1;
        intr_id <= final_id;
        req_pending <= 1'b1;
      end else if (!intr_req && req_pending) begin
        // 等待重新发送请求的时机
        intr_req <= 1'b1;
      end
    end
  end
endmodule