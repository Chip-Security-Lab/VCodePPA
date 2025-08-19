//SystemVerilog
module MuxBidir #(parameter W=8) (
    inout [W-1:0] bus_a,
    inout [W-1:0] bus_b,
    output [W-1:0] bus_out,
    input sel, oe
);
    // 内部信号定义
    wire [W-1:0] a_in, b_in;
    wire [W-1:0] sub_result;
    wire [W-1:0] mux_out;
    
    // 输入缓冲
    assign a_in = bus_a;
    assign b_in = bus_b;
    
    // 简化减法器实现 - 使用进位传播方法
    wire [W-1:0] diff;
    wire [W:0] carry;
    
    // 初始化进位
    assign carry[0] = 1'b1; // 减法需要借位
    
    // 计算每一位的差值和进位
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : sub_loop
            assign diff[i] = a_in[i] ^ b_in[i] ^ carry[i];
            assign carry[i+1] = (~a_in[i] & b_in[i]) | (~a_in[i] & carry[i]) | (b_in[i] & carry[i]);
        end
    endgenerate
    
    // 选择输出 - 修复原代码中的逻辑错误
    assign mux_out = sel ? a_in : diff;
    
    // 三态输出控制
    assign bus_a = (sel && oe) ? mux_out : 'bz;
    assign bus_b = (!sel && oe) ? mux_out : 'bz;
    assign bus_out = sel ? a_in : b_in;

endmodule