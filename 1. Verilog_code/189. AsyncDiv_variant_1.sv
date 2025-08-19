//SystemVerilog
module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    // 流水线寄存器
    reg [15:0] x_stage1, y_stage1;
    reg [15:0] x_stage2, y_stage2;
    reg [15:0] x_stage3, y_stage3;
    reg zero_check_stage1, zero_check_stage2, zero_check_stage3;
    reg [15:0] division_result;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：寄存输入并检查除数是否为零
    always @(posedge clk) begin
        if (en) begin
            x_stage1 <= x;
            y_stage1 <= y;
            zero_check_stage1 <= (y != 0);
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：准备除法操作
    always @(posedge clk) begin
        if (valid_stage1) begin
            x_stage2 <= x_stage1;
            y_stage2 <= y_stage1;
            zero_check_stage2 <= zero_check_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线：执行除法操作
    always @(posedge clk) begin
        if (valid_stage2) begin
            x_stage3 <= x_stage2;
            y_stage3 <= y_stage2;
            zero_check_stage3 <= zero_check_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // 第四级流水线：计算最终结果
    always @(posedge clk) begin
        if (valid_stage3) begin
            division_result <= zero_check_stage3 ? (x_stage3 / y_stage3) : 16'hFFFF;
        end
    end
    
    // 输出结果
    always @(posedge clk) begin
        if (valid_stage3)
            q <= division_result;
    end
endmodule