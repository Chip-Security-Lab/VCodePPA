//SystemVerilog
module XORChain (
    input clk, rst_n,
    input [7:0] din,
    input din_valid,
    output reg [7:0] dout,
    output reg dout_valid
);
    // 第一级流水线：输入数据寄存和有效信号
    reg [7:0] din_stage1;
    reg [7:0] prev_stage1;
    reg din_valid_stage1;
    
    // 第二级流水线：XOR计算结果和有效信号
    reg [7:0] xor_result_stage2;
    reg result_valid_stage2;
    
    // 第一级流水线逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            din_stage1 <= 8'b0;
            prev_stage1 <= 8'b0;
            din_valid_stage1 <= 1'b0;
        end
        else begin
            din_stage1 <= din;
            prev_stage1 <= din_stage1;
            din_valid_stage1 <= din_valid;
        end
    end
    
    // 第二级流水线逻辑 - XOR计算
    always @(posedge clk) begin
        if (!rst_n) begin
            xor_result_stage2 <= 8'b0;
            result_valid_stage2 <= 1'b0;
        end
        else begin
            xor_result_stage2 <= prev_stage1 ^ din_stage1;
            result_valid_stage2 <= din_valid_stage1;
        end
    end
    
    // 第三级流水线逻辑 - 输出
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= 8'b0;
            dout_valid <= 1'b0;
        end
        else begin
            dout <= xor_result_stage2;
            dout_valid <= result_valid_stage2;
        end
    end
    
endmodule