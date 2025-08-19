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
    reg [WIDTH-1:0] src_data;
    reg src_flag, meta_flag, dst_flag;
    
    // 源时钟域 - 使用直接比较替代条件求和减法算法
    always @(posedge src_clk) begin
        src_data <= data_in;
        
        // 直接比较替代复杂的减法实现
        // 根据大小比较的本质，可以直接比较两个数值
        src_flag <= (data_in >= threshold);
    end
    
    // 同步器链 - 采用双触发器同步
    always @(posedge dst_clk or negedge rst_n) begin
        if(!rst_n) begin
            meta_flag <= 1'b0;
            dst_flag <= 1'b0;
        end
        else begin
            meta_flag <= src_flag;
            dst_flag <= meta_flag;
        end
    end
    
    // 输出寄存器
    always @(posedge dst_clk or negedge rst_n) begin
        if(!rst_n) begin
            flag_out <= 1'b0;
        end
        else begin
            flag_out <= dst_flag;
        end
    end
endmodule