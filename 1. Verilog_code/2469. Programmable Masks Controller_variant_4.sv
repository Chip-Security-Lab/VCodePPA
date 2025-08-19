//SystemVerilog
module prog_mask_intr_ctrl(
  input wire CLK, nRST,
  input wire [7:0] INTR, MASK,
  input wire UPDATE_MASK,
  output reg [2:0] ID,
  output reg VALID
);
  reg [7:0] mask_reg;
  wire [7:0] masked_intr;
  wire [7:0] priority_mask;
  
  assign masked_intr = INTR & mask_reg;
  
  // 使用条件运算符替代if-else
  always @(posedge CLK or negedge nRST)
    mask_reg <= ~nRST ? 8'hFF : (UPDATE_MASK ? MASK : mask_reg);
  
  // 优化的优先级编码逻辑
  assign priority_mask[7] = masked_intr[7];
  assign priority_mask[6] = masked_intr[6] & ~masked_intr[7];
  assign priority_mask[5] = masked_intr[5] & ~masked_intr[7] & ~masked_intr[6];
  assign priority_mask[4] = masked_intr[4] & ~masked_intr[7] & ~masked_intr[6] & ~masked_intr[5];
  assign priority_mask[3] = masked_intr[3] & ~masked_intr[7] & ~masked_intr[6] & ~masked_intr[5] & ~masked_intr[4];
  assign priority_mask[2] = masked_intr[2] & ~masked_intr[7] & ~masked_intr[6] & ~masked_intr[5] & ~masked_intr[4] & ~masked_intr[3];
  assign priority_mask[1] = masked_intr[1] & ~masked_intr[7] & ~masked_intr[6] & ~masked_intr[5] & ~masked_intr[4] & ~masked_intr[3] & ~masked_intr[2];
  assign priority_mask[0] = masked_intr[0] & ~masked_intr[7] & ~masked_intr[6] & ~masked_intr[5] & ~masked_intr[4] & ~masked_intr[3] & ~masked_intr[2] & ~masked_intr[1];
  
  // 使用条件运算符和优化的优先级逻辑
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      ID <= 3'd0;
      VALID <= 1'b0;
    end else begin
      VALID <= |masked_intr;
      ID <= priority_mask[7] ? 3'd7 : 
            priority_mask[6] ? 3'd6 :
            priority_mask[5] ? 3'd5 :
            priority_mask[4] ? 3'd4 :
            priority_mask[3] ? 3'd3 :
            priority_mask[2] ? 3'd2 :
            priority_mask[1] ? 3'd1 : 3'd0;
    end
  end
endmodule