//SystemVerilog
module pl_reg_accum #(parameter W=8) (
    input wire clk, rst, add_en,
    input wire [W-1:0] add_val,
    output reg [W-1:0] sum
);
    // 流水线寄存器阶段
    reg add_en_stage1;
    reg [W-1:0] add_val_stage1;
    reg [W-1:0] sum_stage1;
    
    // 中间加法结果
    reg [W-1:0] partial_sum;
    
    // 最终结果寄存器
    reg [W-1:0] result_stage2;
    
    // 第一级流水线 - 寄存输入信号和当前累加值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            add_en_stage1 <= 1'b0;
            add_val_stage1 <= {W{1'b0}};
            sum_stage1 <= {W{1'b0}};
        end
        else begin
            add_en_stage1 <= add_en;
            add_val_stage1 <= add_val;
            sum_stage1 <= sum;
        end
    end
    
    // 计算加法的中间结果 - 拆分关键路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            partial_sum <= {W{1'b0}};
        end
        else begin
            partial_sum <= add_en_stage1 ? (sum_stage1 + add_val_stage1) : sum_stage1;
        end
    end
    
    // 最终输出流水线阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_stage2 <= {W{1'b0}};
            sum <= {W{1'b0}};
        end
        else begin
            result_stage2 <= partial_sum;
            sum <= result_stage2;
        end
    end
endmodule