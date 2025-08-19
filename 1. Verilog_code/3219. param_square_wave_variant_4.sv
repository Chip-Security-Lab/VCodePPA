//SystemVerilog
module param_square_wave #(
    parameter WIDTH = 16
)(
    input clock_i,
    input reset_i,
    input [WIDTH-1:0] period_i,
    input [WIDTH-1:0] duty_i,
    output wave_o
);
    // 内部连线
    wire [WIDTH-1:0] counter_next;
    wire counter_reset;
    reg [WIDTH-1:0] counter_r;
    
    // 组合逻辑部分
    counter_logic #(
        .WIDTH(WIDTH)
    ) counter_comb_inst (
        .counter_r(counter_r),
        .period_i(period_i),
        .counter_next(counter_next),
        .counter_reset(counter_reset)
    );
    
    // 波形输出组合逻辑
    wave_generator #(
        .WIDTH(WIDTH)
    ) wave_gen_inst (
        .counter_r(counter_r),
        .duty_i(duty_i),
        .wave_o(wave_o)
    );
    
    // 时序逻辑部分
    always @(posedge clock_i) begin
        if (reset_i)
            counter_r <= {WIDTH{1'b0}};
        else if (counter_reset)
            counter_r <= {WIDTH{1'b0}};
        else
            counter_r <= counter_next;
    end
endmodule

// 计数器组合逻辑模块
module counter_logic #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] counter_r,
    input [WIDTH-1:0] period_i,
    output [WIDTH-1:0] counter_next,
    output counter_reset
);
    // 计数器复位逻辑
    assign counter_reset = (counter_r >= period_i - 1'b1);
    
    // 计数器下一个值逻辑
    assign counter_next = counter_r + 1'b1;
endmodule

// 波形生成组合逻辑模块
module wave_generator #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] counter_r,
    input [WIDTH-1:0] duty_i,
    output wave_o
);
    // 波形输出逻辑
    assign wave_o = (counter_r < duty_i);
endmodule