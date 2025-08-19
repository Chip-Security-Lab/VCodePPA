//SystemVerilog
module counter_mac #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    input valid_in,
    output valid_out,
    output [2*WIDTH-1:0] sum
);

    // 乘法计算结果
    wire [2*WIDTH-1:0] mult_result;
    
    // 流水线寄存器
    reg [2*WIDTH-1:0] mult_result_stage1;
    reg valid_stage1;
    reg [2*WIDTH-1:0] mult_result_stage2;
    reg valid_stage2;
    reg [2*WIDTH-1:0] sum_reg;
    
    // 乘法运算
    assign mult_result = a * b;
    
    // 流水线第一级 - 乘法结果寄存
    always @(posedge clk) begin
        if (rst) begin
            mult_result_stage1 <= {(2*WIDTH){1'b0}};
        end
        else begin
            mult_result_stage1 <= mult_result;
        end
    end
    
    // 流水线第一级 - 有效信号寄存
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线第二级 - 乘法结果传递
    always @(posedge clk) begin
        if (rst) begin
            mult_result_stage2 <= {(2*WIDTH){1'b0}};
        end
        else begin
            mult_result_stage2 <= mult_result_stage1;
        end
    end
    
    // 流水线第二级 - 有效信号传递
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 累加器逻辑
    always @(posedge clk) begin
        if (rst) begin
            sum_reg <= {(2*WIDTH){1'b0}};
        end
        else if (valid_stage2) begin
            sum_reg <= sum_reg + mult_result_stage2;
        end
    end
    
    // 输出赋值
    assign sum = sum_reg;
    assign valid_out = valid_stage2;

endmodule