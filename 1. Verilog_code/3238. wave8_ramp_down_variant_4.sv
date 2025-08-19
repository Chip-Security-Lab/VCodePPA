//SystemVerilog
module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // 使用带状进位加法器(Carry-Lookahead Adder)实现减法器
    wire [WIDTH-1:0] step_comp;      // STEP的反码
    wire [WIDTH-1:0] sub_result;     // 减法结果
    
    // 生成STEP的反码
    assign step_comp = ~STEP;
    
    // 中间进位信号
    wire [WIDTH:0] c;  // 进位信号，多一位用于最终进位
    wire [WIDTH-1:0] g, p;  // 生成和传播信号
    
    // 为减法操作设置初始进位为1
    assign c[0] = 1'b1;
    
    // 计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: cla_signals
            assign g[i] = wave_out[i] & step_comp[i];
            assign p[i] = wave_out[i] | step_comp[i];
        end
    endgenerate
    
    // 带状进位加法器实现
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: cla_logic
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sub_result[i] = wave_out[i] ^ step_comp[i] ^ c[i];
        end
    endgenerate
    
    always @(posedge clk) begin
        if(rst) wave_out <= {WIDTH{1'b1}};
        else    wave_out <= sub_result;
    end
endmodule