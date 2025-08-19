//SystemVerilog
module PredictCompress (
    input clk, en,
    input [15:0] current,
    output reg [7:0] delta
);
    reg [15:0] prev_reg;
    reg [15:0] current_reg;
    wire [3:0] diff1, diff2, diff3, diff4;
    wire [15:0] full_diff;
    
    // 查找表 - 4位减法结果
    function [3:0] sub_lut;
        input [3:0] a, b;
        begin
            case ({a, b})
                // 部分查找表条目，实际实现需要完整的查找表
                8'h00: sub_lut = 4'h0; // 0-0
                8'h10: sub_lut = 4'h1; // 1-0
                8'h21: sub_lut = 4'h1; // 2-1
                8'h32: sub_lut = 4'h1; // 3-2
                // ...其他组合
                default: sub_lut = a - b; // 默认使用正常减法
            endcase
        end
    endfunction
    
    // 寄存输入
    always @(posedge clk) begin
        if(en) begin
            current_reg <= current;
            prev_reg <= current_reg;
        end
    end
    
    // 计算各个4位分组的减法结果，使用寄存后的输入
    assign diff1 = sub_lut(current_reg[3:0], prev_reg[3:0]);
    assign diff2 = sub_lut(current_reg[7:4], prev_reg[7:4]);
    assign diff3 = sub_lut(current_reg[11:8], prev_reg[11:8]);
    assign diff4 = sub_lut(current_reg[15:12], prev_reg[15:12]);
    
    // 组合完整的16位差值
    assign full_diff = {diff4, diff3, diff2, diff1};
    
    // 输出寄存器
    always @(posedge clk) begin
        if(en) begin
            delta <= full_diff[7:0]; // 取低8位作为输出
        end
    end
endmodule