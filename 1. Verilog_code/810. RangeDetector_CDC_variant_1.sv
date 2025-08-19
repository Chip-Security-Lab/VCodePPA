//SystemVerilog
module RangeDetector_CDC #(
    parameter WIDTH = 8
)(
    input src_clk,
    input dst_clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag_out
);

    // 源时钟域比较逻辑信号
    reg src_flag;
    
    // CDC同步信号链
    reg meta_flag;
    reg dst_flag;
    
    // 源时钟域比较逻辑 - 负责检测data_in是否超过阈值
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n)
            src_flag <= 1'b0;
        else
            src_flag <= (data_in > threshold);
    end
    
    // CDC第一级同步 - 防止亚稳态
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n)
            meta_flag <= 1'b0;
        else
            meta_flag <= src_flag;
    end
    
    // CDC第二级同步和输出逻辑合并 - 减少一级寄存器延迟
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_flag <= 1'b0;
            flag_out <= 1'b0;
        end
        else begin
            dst_flag <= meta_flag;
            flag_out <= dst_flag;
        end
    end

endmodule