//SystemVerilog
module multi_bit_clock_gate #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output wire [WIDTH-1:0] clk_out
);
    // 使用非阻塞赋值以避免潜在的竞态条件
    reg [WIDTH-1:0] enable_latch;
    
    // 时钟低电平时锁存使能信号，提高稳定性
    always @(clk_in or enable_vector) begin
        if (!clk_in)
            enable_latch <= enable_vector;
    end
    
    // 输出时钟门控
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gate_gen
            assign clk_out[i] = clk_in & enable_latch[i];
        end
    endgenerate
endmodule