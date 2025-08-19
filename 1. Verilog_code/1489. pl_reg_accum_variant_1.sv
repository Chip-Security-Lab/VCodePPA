//SystemVerilog
module pl_reg_accum #(
    parameter W = 8
) (
    input  wire        clk,     // 时钟信号
    input  wire        rst,     // 复位信号
    input  wire        add_en,  // 使能信号
    input  wire [W-1:0] add_val, // 加数输入
    output wire [W-1:0] sum      // 累加结果输出
);
    // 内部信号定义 - 流水线阶段
    reg         add_en_stage1;
    reg [W-1:0] add_val_stage1;
    reg [W-1:0] sum_reg;
    reg [W-1:0] add_result;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk) begin
        if (rst) begin
            add_en_stage1  <= 1'b0;
            add_val_stage1 <= {W{1'b0}};
        end else begin
            add_en_stage1  <= add_en;
            add_val_stage1 <= add_val;
        end
    end
    
    // 第二级流水线：计算加法结果
    always @(posedge clk) begin
        if (rst) begin
            add_result <= {W{1'b0}};
        end else begin
            add_result <= add_en_stage1 ? (sum_reg + add_val_stage1) : sum_reg;
        end
    end
    
    // 第三级流水线：更新累加结果
    always @(posedge clk) begin
        if (rst) begin
            sum_reg <= {W{1'b0}};
        end else begin
            sum_reg <= add_result;
        end
    end
    
    // 输出赋值
    assign sum = sum_reg;

endmodule