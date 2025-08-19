//SystemVerilog
module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag
);

// 预计算比较结果
wire comp_greater_equal = (data_in >= threshold);
wire comp_less_equal = (data_in <= threshold);
wire comp_not_equal = (data_in != threshold);
wire comp_equal = (data_in == threshold);

// 模式选择逻辑
wire [3:0] mode_decode = {
    (mode == 2'b11),  // equal
    (mode == 2'b10),  // not equal
    (mode == 2'b01),  // less equal
    (mode == 2'b00)   // greater equal
};

// 组合选择逻辑
wire flag_next = (mode_decode[0] & comp_greater_equal) |
                 (mode_decode[1] & comp_less_equal) |
                 (mode_decode[2] & comp_not_equal) |
                 (mode_decode[3] & comp_equal);

// 时序逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag <= 1'b0;
    end else begin
        flag <= flag_next;
    end
end

endmodule