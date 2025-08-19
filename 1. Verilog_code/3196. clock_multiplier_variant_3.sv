//SystemVerilog
//===================================================================
// 顶层模块
//===================================================================
module clock_multiplier #(
    parameter MULT_RATIO = 4
)(
    input  wire clk_ref,
    output wire clk_out
);
    // 内部连线
    wire [1:0] phase_count;
    
    // 实例化计数器子模块
    phase_counter_module phase_counter_inst (
        .clk_ref       (clk_ref),
        .phase_count   (phase_count)
    );
    
    // 实例化时钟生成子模块
    clock_generator_module clock_gen_inst (
        .phase_count   (phase_count),
        .clk_out       (clk_out)
    );
    
endmodule

//===================================================================
// 相位计数器子模块
//===================================================================
module phase_counter_module (
    input  wire       clk_ref,
    output reg  [1:0] phase_count
);
    // 相位计数逻辑
    always @(negedge clk_ref) begin
        phase_count <= phase_count + 1'b1;
    end
    
endmodule

//===================================================================
// 时钟生成子模块
//===================================================================
module clock_generator_module (
    input  wire [1:0] phase_count,
    output wire       clk_out
);
    // 从计数器的最高位产生时钟输出
    assign clk_out = phase_count[1];
    
endmodule