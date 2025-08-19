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

    // LZ77压缩窗口逻辑
    reg [RAW_WIDTH-1:0] search_buffer [0:7];
    reg [2:0] wr_ptr;
    
    // 条件反相减法器相关信号
    wire [7:0] raw_byte;
    wire [7:0] inv_raw_byte;
    wire [7:0] sub_result;
    wire sub_carry;
    
    // 提取8位数据
    assign raw_byte = raw_data[7:0];
    
    // 条件反相
    assign inv_raw_byte = ~raw_byte;
    
    // 条件减法
    assign {sub_carry, sub_result} = compress_en ? 
        {1'b0, raw_byte} - {1'b0, inv_raw_byte} : 
        {1'b0, raw_byte};
    
    always @(posedge clk) begin
        comp_data <= compress_en ? {3'b001, sub_result} : comp_data;
        comp_valid <= compress_en ? 1'b1 : 1'b0;
    end

endmodule