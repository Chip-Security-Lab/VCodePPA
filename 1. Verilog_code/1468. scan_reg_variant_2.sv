//SystemVerilog
module scan_reg(
    input clk, rst_n,
    input [7:0] parallel_data,
    input scan_in, scan_en, load,
    output reg [7:0] data_out,
    output scan_out
);
    // 流水线级别寄存器
    reg [7:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    reg stage1_scan_out, stage2_scan_out;
    
    // 输入阶段控制信号
    reg [7:0] input_data;
    reg input_valid;
    reg input_scan_out;
    
    // 第一流水线级别 - 输入选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_valid <= 1'b0;
            stage1_scan_out <= 1'b0;
        end else begin
            // 输入选择逻辑
            stage1_data <= scan_en ? {data_out[6:0], scan_in} :
                          load    ? parallel_data :
                                    data_out;
            stage1_valid <= 1'b1;
            stage1_scan_out <= scan_en ? data_out[6] : data_out[7]; 
        end
    end
    
    // 第二流水线级别 - 中间处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 8'b0;
            stage2_valid <= 1'b0;
            stage2_scan_out <= 1'b0;
        end else if (stage1_valid) begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
            stage2_scan_out <= stage1_scan_out;
        end
    end
    
    // 输出流水线级别 - 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else if (stage2_valid) begin
            data_out <= stage2_data;
        end
    end
    
    // 输出扫描信号
    assign scan_out = data_out[7];
    
    // 流水线启动和刷新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_valid <= 1'b0;
        end else begin
            input_valid <= 1'b1; // 启动流水线
        end
    end
endmodule