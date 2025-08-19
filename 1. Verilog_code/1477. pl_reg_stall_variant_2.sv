//SystemVerilog
module pl_reg_stall #(parameter W=4) (
    input clk, rst, load, stall,
    input [W-1:0] new_data,
    output reg [W-1:0] current_data
);
    // 流水线寄存器
    reg [W-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    // 第一级流水线 - 数据处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_data <= {W{1'b0}};
        end else if (!stall) begin
            stage1_data <= load ? new_data : current_data;
        end
    end
    
    // 第一级流水线 - 有效位处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_valid <= 1'b0;
        end else if (!stall) begin
            stage1_valid <= 1'b1;
        end
    end
    
    // 第二级流水线 - 数据处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= {W{1'b0}};
        end else if (!stall) begin
            stage2_data <= stage1_data;
        end
    end
    
    // 第二级流水线 - 有效位处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_valid <= 1'b0;
        end else if (!stall) begin
            stage2_valid <= stage1_valid;
        end
    end
    
    // 输出级 - 条件更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_data <= {W{1'b0}};
        end else if (!stall && stage2_valid) begin
            current_data <= stage2_data;
        end
    end
endmodule