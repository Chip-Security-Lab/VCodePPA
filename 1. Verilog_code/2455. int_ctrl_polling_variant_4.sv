//SystemVerilog
module int_ctrl_polling #(parameter CNT_W=3)(
    input clk, enable,
    input [2**CNT_W-1:0] int_src,
    output reg int_valid,
    output [CNT_W-1:0] int_id
);
    reg [CNT_W-1:0] poll_counter;
    wire [CNT_W-1:0] next_counter;
    wire carry_out;
    
    // 条件反相减法器实现计数器递增
    // 实际上是 poll_counter + 1 的实现
    conditional_inverting_subtractor #(
        .WIDTH(CNT_W)
    ) cis_inst (
        .a(poll_counter),
        .b({(CNT_W){1'b0}}),  // 全0
        .subtract(1'b1),      // 执行 a - (-1) = a + 1
        .result(next_counter),
        .carry_out(carry_out)
    );
    
    always @(posedge clk) begin
        if(enable) poll_counter <= next_counter;
        int_valid <= int_src[poll_counter];
    end
    
    assign int_id = poll_counter;
endmodule

// 条件反相减法器模块实现
module conditional_inverting_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input subtract,
    output [WIDTH-1:0] result,
    output carry_out
);
    wire [WIDTH-1:0] b_conditional;
    wire [WIDTH:0] carries;
    
    // 当subtract为1时对b进行反相
    assign b_conditional = b ^ {WIDTH{subtract}};
    // 初始进位等于subtract信号
    assign carries[0] = subtract;
    
    // 按位计算结果和进位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            assign result[i] = a[i] ^ b_conditional[i] ^ carries[i];
            assign carries[i+1] = (a[i] & b_conditional[i]) | 
                                 (a[i] & carries[i]) | 
                                 (b_conditional[i] & carries[i]);
        end
    endgenerate
    
    // 最高位进位输出
    assign carry_out = carries[WIDTH];
endmodule