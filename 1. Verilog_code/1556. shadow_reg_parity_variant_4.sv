//SystemVerilog
module shadow_reg_parity_pipeline #(parameter DW=8) (
    input clk, rstn, en,
    input [DW-1:0] din,
    output reg [DW:0] dout  // [DW]位为校验位
);

    // 使用更高效的奇偶校验计算方式
    reg [DW-1:0] din_stage2;
    reg parity_stage2;
    reg [DW:0] dout_next;
    
    // 减少逻辑层级的奇偶校验计算
    // 将大位宽XOR分解为多个小位宽XOR并行计算
    wire [(DW/2)-1:0] parity_parts;
    genvar i;
    generate
        for(i = 0; i < DW/2; i = i + 1) begin : parity_gen
            assign parity_parts[i] = din[i*2] ^ din[i*2+1];
        end
    endgenerate
    
    wire parity_stage1 = ^parity_parts;
    
    // 合并始终块，减少寄存器数量
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            din_stage2 <= {DW{1'b0}};
            parity_stage2 <= 1'b0;
            dout <= {(DW+1){1'b0}};
        end else if (en) begin
            din_stage2 <= din;
            parity_stage2 <= parity_stage1;
            dout <= dout_next;
        end
    end
    
    // 使用组合逻辑预计算下一个输出值
    always @(*) begin
        dout_next = {parity_stage2, din_stage2};
    end

endmodule