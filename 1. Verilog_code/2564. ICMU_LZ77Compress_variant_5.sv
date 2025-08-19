//SystemVerilog
module ICMU_LZ77Compress #(
    parameter RAW_WIDTH = 64,
    parameter COMP_WIDTH = 32
)(
    input clk,
    input rst_n,
    input compress_en,
    input [RAW_WIDTH-1:0] raw_data,
    output reg [COMP_WIDTH-1:0] comp_data,
    output reg comp_valid
);

    // 搜索缓冲区寄存器
    reg [RAW_WIDTH-1:0] search_buffer [0:7];
    reg [2:0] wr_ptr;
    
    // 压缩控制信号
    reg comp_active;
    
    // 搜索缓冲区更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 3'b0;
        end else if (compress_en) begin
            search_buffer[wr_ptr] <= raw_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
    // 压缩使能控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_active <= 1'b0;
        end else begin
            comp_active <= compress_en;
        end
    end
    
    // 压缩数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_data <= {COMP_WIDTH{1'b0}};
            comp_valid <= 1'b0;
        end else if (comp_active) begin
            comp_data <= {3'b001, raw_data[7:0]};
            comp_valid <= 1'b1;
        end else begin
            comp_valid <= 1'b0;
        end
    end

endmodule