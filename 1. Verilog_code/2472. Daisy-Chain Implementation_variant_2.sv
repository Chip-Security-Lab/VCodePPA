//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module daisy_chain_intr_ctrl(
  input clk, rst_n,
  input [3:0] requests,
  input valid_in,    // 替代了原来的chain_in
  output ready_out,  // 新增ready信号给上游模块
  output [1:0] local_id,
  output valid_out,  // 替代了原来的chain_out
  input ready_in,    // 新增ready信号从下游模块
  output grant
);
  // 流水线阶段1: 请求接收和缓存
  reg [3:0] req_buffer_stage1;
  reg processing_stage1;
  reg valid_stage1;
  
  // 流水线阶段2: 优先级编码
  reg [3:0] req_buffer_stage2;
  reg processing_stage2;
  reg valid_stage2;
  reg [1:0] local_id_stage2;
  reg local_req_stage2;
  
  // 流水线阶段3: 授权和输出控制
  reg processing_stage3;
  reg valid_stage3;
  reg [1:0] local_id_reg_stage3;
  reg local_req_stage3;
  reg grant_reg;
  
  // 流水线控制信号
  wire stage1_ready;
  wire stage2_ready;
  wire stage3_ready;
  
  // 阶段1: 请求接收和缓存
  wire has_new_req = |requests & !processing_stage1;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_buffer_stage1 <= 4'b0;
      processing_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end
    else if (stage1_ready) begin
      if (has_new_req) begin
        req_buffer_stage1 <= requests;
        processing_stage1 <= 1'b1;
        valid_stage1 <= 1'b1;
      end
      else if (valid_in) begin
        req_buffer_stage1 <= 4'b0;
        processing_stage1 <= 1'b0;
        valid_stage1 <= 1'b1;
      end
      else begin
        valid_stage1 <= 1'b0;
      end
    end
  end
  
  // 阶段2: 优先级编码
  wire req0_valid_stage1 = req_buffer_stage1[0];
  wire req1_valid_stage1 = req_buffer_stage1[1] & ~req0_valid_stage1;
  wire req2_valid_stage1 = req_buffer_stage1[2] & ~req0_valid_stage1 & ~req1_valid_stage1;
  wire req3_valid_stage1 = req_buffer_stage1[3] & ~req0_valid_stage1 & ~req1_valid_stage1 & ~req2_valid_stage1;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_buffer_stage2 <= 4'b0;
      processing_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
      local_id_stage2 <= 2'd0;
      local_req_stage2 <= 1'b0;
    end
    else if (stage2_ready) begin
      if (valid_stage1) begin
        req_buffer_stage2 <= req_buffer_stage1;
        processing_stage2 <= processing_stage1;
        valid_stage2 <= 1'b1;
        local_req_stage2 <= |req_buffer_stage1;
        
        if (req0_valid_stage1)
          local_id_stage2 <= 2'd0;
        else if (req1_valid_stage1)
          local_id_stage2 <= 2'd1;
        else if (req2_valid_stage1)
          local_id_stage2 <= 2'd2;
        else if (req3_valid_stage1)
          local_id_stage2 <= 2'd3;
        else
          local_id_stage2 <= 2'd0;
      end
      else begin
        valid_stage2 <= 1'b0;
      end
    end
  end
  
  // 阶段3: 授权和输出控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      processing_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      local_id_reg_stage3 <= 2'd0;
      local_req_stage3 <= 1'b0;
      grant_reg <= 1'b0;
    end
    else if (stage3_ready) begin
      if (valid_stage2) begin
        processing_stage3 <= processing_stage2;
        valid_stage3 <= 1'b1;
        local_id_reg_stage3 <= local_id_stage2;
        local_req_stage3 <= local_req_stage2;
        
        // 授权逻辑
        if (local_req_stage2 & valid_stage2 & !grant_reg) begin
          grant_reg <= 1'b1;
        end
        else if (ready_in & grant_reg) begin
          grant_reg <= 1'b0;
        end
      end
      else begin
        valid_stage3 <= 1'b0;
      end
    end
    else if (ready_in & grant_reg) begin
      grant_reg <= 1'b0;
    end
  end
  
  // 流水线控制逻辑
  assign stage3_ready = ready_in | ~valid_stage3 | ~local_req_stage3;
  assign stage2_ready = ~valid_stage2 | stage3_ready;
  assign stage1_ready = ~valid_stage1 | stage2_ready;
  
  // 输出赋值
  assign ready_out = stage1_ready;
  assign valid_out = valid_stage3 & ~local_req_stage3;
  assign local_id = local_id_reg_stage3;
  assign grant = grant_reg;
  
endmodule