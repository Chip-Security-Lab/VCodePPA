//SystemVerilog
module shadow_reg_parity #(parameter DW=8) (
    input clk, rstn, en,
    input [DW-1:0] din,
    output reg [DW:0] dout  // [DW]位为校验位
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线 - 拆分数据计算部分校验和
    reg [DW/4-1:0] parity_quarter1_stage1, parity_quarter2_stage1;
    reg [DW/4-1:0] parity_quarter3_stage1, parity_quarter4_stage1;
    reg [DW-1:0] din_stage1;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            parity_quarter1_stage1 <= 0;
            parity_quarter2_stage1 <= 0;
            parity_quarter3_stage1 <= 0;
            parity_quarter4_stage1 <= 0;
            din_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if(en) begin
            // 将数据分成四个部分计算初级校验
            parity_quarter1_stage1 <= ^(din[DW/4-1:0]);
            parity_quarter2_stage1 <= ^(din[DW/2-1:DW/4]);
            parity_quarter3_stage1 <= ^(din[3*DW/4-1:DW/2]);
            parity_quarter4_stage1 <= ^(din[DW-1:3*DW/4]);
            din_stage1 <= din;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 0;
        end
    end
    
    // 第二级流水线 - 合并四个部分的校验结果
    reg [1:0] parity_half1_stage2, parity_half2_stage2;
    reg [DW-1:0] din_stage2;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            parity_half1_stage2 <= 0;
            parity_half2_stage2 <= 0;
            din_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else if(valid_stage1) begin
            // 合并每两个部分的校验位
            parity_half1_stage2 <= parity_quarter1_stage1 ^ parity_quarter2_stage1;
            parity_half2_stage2 <= parity_quarter3_stage1 ^ parity_quarter4_stage1;
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 0;
        end
    end
    
    // 第三级流水线 - 计算最终校验位并输出结果
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            dout <= 0;
            valid_stage3 <= 0;
        end
        else if(valid_stage2) begin
            // 计算最终校验位并与数据合并
            dout <= {parity_half1_stage2[0] ^ parity_half2_stage2[0], din_stage2};
            valid_stage3 <= valid_stage2;
        end
        else begin
            valid_stage3 <= 0;
        end
    end
endmodule