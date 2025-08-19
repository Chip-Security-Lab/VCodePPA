//SystemVerilog
// 顶层模块
module prog_mask_intr_ctrl (
  input  wire       CLK, nRST,
  input  wire [7:0] INTR, MASK,
  input  wire       UPDATE_MASK,
  output wire [2:0] ID,
  output wire       VALID
);
  
  // 内部信号
  wire [7:0] mask_reg;
  wire [7:0] masked_intr;
  
  // 实例化掩码控制子模块
  mask_controller mask_ctrl_inst (
    .CLK         (CLK),
    .nRST        (nRST),
    .MASK        (MASK),
    .UPDATE_MASK (UPDATE_MASK),
    .mask_reg    (mask_reg)
  );
  
  // 实例化中断掩码应用子模块
  interrupt_masking intr_mask_inst (
    .INTR        (INTR),
    .mask_reg    (mask_reg),
    .masked_intr (masked_intr)
  );
  
  // 实例化优先级编码器子模块
  priority_encoder pri_enc_inst (
    .CLK         (CLK),
    .nRST        (nRST),
    .masked_intr (masked_intr),
    .ID          (ID),
    .VALID       (VALID)
  );
  
endmodule

// 掩码控制子模块
module mask_controller (
  input  wire       CLK, nRST,
  input  wire [7:0] MASK,
  input  wire       UPDATE_MASK,
  output reg  [7:0] mask_reg
);
  
  // 掩码寄存器更新逻辑
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      mask_reg <= 8'hFF;
    end else if (UPDATE_MASK) begin
      mask_reg <= MASK;
    end
  end
  
endmodule

// 中断掩码应用子模块
module interrupt_masking (
  input  wire [7:0] INTR,
  input  wire [7:0] mask_reg,
  output wire [7:0] masked_intr
);
  
  // 使用非阻塞赋值以改善PPA指标
  assign masked_intr = INTR & mask_reg;
  
endmodule

// 优先级编码器子模块
module priority_encoder (
  input  wire       CLK, nRST,
  input  wire [7:0] masked_intr,
  output reg  [2:0] ID,
  output reg        VALID
);
  
  // 优化的中断检测和优先级编码逻辑
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      ID    <= 3'd0;
      VALID <= 1'b0;
    end else begin
      // 使用组合运算符简化有效中断检测
      VALID <= |masked_intr;
      
      // 优化的优先级编码逻辑
      casez (masked_intr)
        8'b1???????: ID <= 3'd7;
        8'b01??????: ID <= 3'd6;
        8'b001?????: ID <= 3'd5;
        8'b0001????: ID <= 3'd4;
        8'b00001???: ID <= 3'd3;
        8'b000001??: ID <= 3'd2;
        8'b0000001?: ID <= 3'd1;
        8'b00000001: ID <= 3'd0;
        default:     ID <= 3'd0;
      endcase
    end
  end
  
endmodule