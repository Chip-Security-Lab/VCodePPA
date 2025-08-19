//SystemVerilog
module DelayCompBridge #(
    parameter DELAY_CYC = 3
)(
    input clk, rst_n,
    input [31:0] data_in,
    output [31:0] data_out
);
    // 查找表辅助减法器算法实现
    reg [31:0] delay_chain [0:DELAY_CYC-1];
    reg [31:0] lut_result;
    reg [3:0] lut_index;
    reg [31:0] subtraction_result;
    
    // 减法器查找表 - 存储常用减法结果
    reg [31:0] sub_lut [0:15];
    
    // 初始化查找表
    initial begin
        sub_lut[0] = 32'h00000000;
        sub_lut[1] = 32'hFFFFFFFF; // -1
        sub_lut[2] = 32'hFFFFFFFE; // -2
        sub_lut[3] = 32'hFFFFFFFD; // -3
        sub_lut[4] = 32'hFFFFFFFC; // -4
        sub_lut[5] = 32'hFFFFFFFB; // -5
        sub_lut[6] = 32'hFFFFFFFA; // -6
        sub_lut[7] = 32'hFFFFFFF9; // -7
        sub_lut[8] = 32'hFFFFFFF8; // -8
        sub_lut[9] = 32'h00000001; // 1
        sub_lut[10] = 32'h00000002; // 2
        sub_lut[11] = 32'h00000003; // 3
        sub_lut[12] = 32'h00000004; // 4
        sub_lut[13] = 32'h00000005; // 5
        sub_lut[14] = 32'h00000006; // 6
        sub_lut[15] = 32'h00000007; // 7
    end
    
    // 查找表索引生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_index <= 4'b0;
        end else begin
            // 使用数据的低4位作为查找表索引
            lut_index <= data_in[3:0];
        end
    end
    
    // 查找表查询
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_result <= 32'b0;
        end else begin
            lut_result <= sub_lut[lut_index];
        end
    end
    
    // 完成最终减法计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            subtraction_result <= 32'b0;
        end else begin
            // 对于不在LUT中的值，执行标准减法
            if (|data_in[31:4]) begin
                subtraction_result <= data_in - 32'd1;
            end else begin
                // 使用查找表结果
                subtraction_result <= lut_result;
            end
        end
    end
    
    // 延迟链逻辑 - 存储计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 使用generate块风格的初始化，减少循环逻辑
            delay_chain[0] <= 32'b0;
            if (DELAY_CYC > 1) begin
                delay_chain[1] <= 32'b0;
                if (DELAY_CYC > 2) begin
                    delay_chain[2] <= 32'b0;
                    // 可扩展到更多级数
                end
            end
        end else begin
            // 流水线式数据移动，避免使用循环
            delay_chain[0] <= subtraction_result;
            if (DELAY_CYC > 1) delay_chain[1] <= delay_chain[0];
            if (DELAY_CYC > 2) delay_chain[2] <= delay_chain[1];
            // 可扩展到更多级数
        end
    end
    
    // 直接连接输出，减少逻辑延迟
    assign data_out = delay_chain[DELAY_CYC-1];
    
endmodule