//SystemVerilog
module cam_10 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] wide_data_in,
    output reg wide_match,
    output reg [15:0] wide_store_data
);

    // 比较结果信号
    wire [15:0] compare_result;
    wire match_en;
    
    // 组合逻辑：数据比较
    assign compare_result = wide_store_data ^ wide_data_in;
    assign match_en = ~|compare_result;
    
    // 时序逻辑：数据存储
    always @(posedge clk) begin
        if (rst) begin
            wide_store_data <= 16'b0;
        end else if (write_en) begin
            wide_store_data <= wide_data_in;
        end
    end
    
    // 时序逻辑：匹配结果生成
    always @(posedge clk) begin
        if (rst) begin
            wide_match <= 1'b0;
        end else if (write_en) begin
            wide_match <= 1'b0;
        end else begin
            wide_match <= match_en;
        end
    end

endmodule