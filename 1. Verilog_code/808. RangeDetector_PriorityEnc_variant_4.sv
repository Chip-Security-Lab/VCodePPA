//SystemVerilog
module RangeDetector_LUT #(
    parameter WIDTH = 8,
    parameter ZONES = 4
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_limits [ZONES:0],
    output reg [$clog2(ZONES)-1:0] zone_num
);

// 定义LUT来辅助计算减法结果
reg [WIDTH-1:0] diff_lut [ZONES-1:0];
reg [ZONES-1:0] compare_results;
wire [$clog2(ZONES)-1:0] encoded_zone;

// 使用查找表辅助减法运算
always @(*) begin
    for(int j = 0; j < ZONES; j = j+1) begin
        // 计算减法结果并存入LUT
        diff_lut[j] = data_in - zone_limits[j]; 
        // 使用LUT值进行比较判断
        compare_results[j] = (diff_lut[j] < (zone_limits[j+1] - zone_limits[j])) &&
                             (data_in >= zone_limits[j]);
    end
end

// 使用桶形编码器结构
generate
    if (ZONES == 2) begin
        assign encoded_zone = compare_results[1] ? 1'b1 : 1'b0;
    end else if (ZONES <= 4) begin
        assign encoded_zone = compare_results[3] ? 2'd3 :
                             compare_results[2] ? 2'd2 :
                             compare_results[1] ? 2'd1 : 2'd0;
    end else if (ZONES <= 8) begin
        assign encoded_zone = compare_results[7] ? 3'd7 :
                             compare_results[6] ? 3'd6 :
                             compare_results[5] ? 3'd5 :
                             compare_results[4] ? 3'd4 :
                             compare_results[3] ? 3'd3 :
                             compare_results[2] ? 3'd2 :
                             compare_results[1] ? 3'd1 : 3'd0;
    end else begin
        // 通用桶形结构，支持更多区域
        reg [$clog2(ZONES)-1:0] barrel_out;
        always @(*) begin
            barrel_out = {$clog2(ZONES){1'b0}};
            for(int j = ZONES-1; j >= 0; j = j-1) begin
                if(compare_results[j]) begin
                    barrel_out = j[$clog2(ZONES)-1:0];
                end
            end
        end
        assign encoded_zone = barrel_out;
    end
endgenerate

// 输出区域编号
always @(*) begin
    zone_num = encoded_zone;
end

endmodule