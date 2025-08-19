//SystemVerilog
module default_value_mux #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input [WIDTH-1:0] data_a, data_b, data_c,
    input [1:0] mux_select,
    input use_default,
    output [WIDTH-1:0] mux_result
);
    wire [1:0] diff;
    wire [WIDTH-1:0] mux_out;
    
    // 优化的减法逻辑 - 使用布尔代数简化
    assign diff[0] = data_a[0] ^ data_b[0];
    assign diff[1] = (data_a[1] ^ data_b[1]) ^ (data_b[0] & ~data_a[0]);
    
    // 优化的多路复用器 - 使用位运算和掩码
    wire [WIDTH-1:0] mask_a = {WIDTH{mux_select == 2'b00}};
    wire [WIDTH-1:0] mask_b = {WIDTH{mux_select == 2'b01}};
    wire [WIDTH-1:0] mask_c = {WIDTH{mux_select == 2'b10}};
    wire [WIDTH-1:0] mask_d = {WIDTH{mux_select == 2'b11}};
    
    assign mux_out = (mask_a & {data_a[WIDTH-1:2], diff}) |
                    (mask_b & {data_b[WIDTH-1:2], diff}) |
                    (mask_c & {data_c[WIDTH-1:2], diff}) |
                    (mask_d & DEFAULT_VAL);
    
    // 优化的输出选择逻辑
    assign mux_result = (use_default ? DEFAULT_VAL : mux_out);
endmodule