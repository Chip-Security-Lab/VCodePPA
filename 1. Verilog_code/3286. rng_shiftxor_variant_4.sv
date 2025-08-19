//SystemVerilog
// rng_shiftxor_6_top.v
module rng_shiftxor_6(
    input             clk,
    input             rst,
    input             en,
    output [7:0]      rnd
);
    wire [7:0] prng_main_reg_out;
    wire [7:0] buffer1_out;
    wire [7:0] buffer2_out;

    // 主伪随机数发生寄存器单元
    prng_main_reg_retimed #(
        .INIT_VAL(8'hF0)
    ) u_prng_main_reg (
        .clk(clk),
        .rst(rst),
        .en(en),
        .prng_out(prng_main_reg_out)
    );

    // 一级缓冲寄存器单元（已移除，重定时后由主寄存器输出直接提供）
    // 二级缓冲寄存器单元（已移除，重定时后由主寄存器输出直接提供）

    assign buffer1_out = prng_main_reg_out;
    assign buffer2_out = buffer1_out;
    assign rnd = buffer2_out;

endmodule

//-----------------------------
// 伪随机数主寄存器模块（重定时版）
// 已将原有两个输出缓冲寄存器集成到主寄存器模块的前端
//-----------------------------
module prng_main_reg_retimed #(
    parameter [7:0] INIT_VAL = 8'hF0
)(
    input        clk,
    input        rst,
    input        en,
    output [7:0] prng_out
);
    reg [7:0] prng_stage0;
    reg [7:0] prng_stage1;
    reg [7:0] prng_stage2;

    wire mix_bit;
    assign mix_bit = ^(prng_stage0[7:4]);

    always @(posedge clk) begin
        if (rst) begin
            prng_stage0 <= INIT_VAL;
            prng_stage1 <= INIT_VAL;
            prng_stage2 <= INIT_VAL;
        end else if (en) begin
            prng_stage0 <= {prng_stage0[6:0], mix_bit};
            prng_stage1 <= prng_stage0;
            prng_stage2 <= prng_stage1;
        end
    end

    assign prng_out = prng_stage2;
endmodule