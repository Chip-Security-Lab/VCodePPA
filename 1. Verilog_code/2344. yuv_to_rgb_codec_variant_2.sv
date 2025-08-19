//SystemVerilog
module yuv_to_rgb_codec #(
    parameter Y_WIDTH = 8,
    parameter UV_WIDTH = 8
) (
    input [Y_WIDTH-1:0] y_in,
    input [UV_WIDTH-1:0] u_in, v_in,
    output reg [23:0] rgb_out
);
    wire signed [15:0] c = y_in - 16;
    wire signed [15:0] d = u_in - 128;
    wire signed [15:0] e = v_in - 128;
    
    reg [7:0] r, g, b;
    reg signed [15:0] r_temp, g_temp, b_temp;
    
    always @(*) begin
        // 计算r_temp, g_temp, b_temp
        r_temp = ((298 * c) + (409 * e) + 128) >> 8;
        g_temp = ((298 * c) - (100 * d) - (208 * e) + 128) >> 8;
        b_temp = ((298 * c) + (516 * d) + 128) >> 8;
        
        // 使用并行比较和范围检查优化RGB值的处理
        r = (r_temp[15]) ? 8'd0 : (|r_temp[15:8]) ? 8'd255 : r_temp[7:0];
        g = (g_temp[15]) ? 8'd0 : (|g_temp[15:8]) ? 8'd255 : g_temp[7:0];
        b = (b_temp[15]) ? 8'd0 : (|b_temp[15:8]) ? 8'd255 : b_temp[7:0];
        
        // 组合RGB输出
        rgb_out = {r, g, b};
    end
endmodule