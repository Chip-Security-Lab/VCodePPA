//SystemVerilog
module nco_sine #(
    parameter PHASE_WIDTH = 12,
    parameter AMP_WIDTH = 8
)(
    input clk,
    input rst,
    input [PHASE_WIDTH-1:0] phase_incr,
    output reg [AMP_WIDTH-1:0] sine_wave
);
    // 相位累加器
    reg [PHASE_WIDTH-1:0] phase_accum;
    
    // 预计算的正弦波查找表 - 使用寄存器实现
    reg [AMP_WIDTH-1:0] sine_rom [0:15];
    
    // 注册输出以减少关键路径
    reg [3:0] rom_addr;
    
    initial begin
        sine_rom[0] = 8'd128; sine_rom[1] = 8'd176; sine_rom[2] = 8'd218; sine_rom[3] = 8'd245;
        sine_rom[4] = 8'd255; sine_rom[5] = 8'd245; sine_rom[6] = 8'd218; sine_rom[7] = 8'd176;
        sine_rom[8] = 8'd128; sine_rom[9] = 8'd79;  sine_rom[10] = 8'd37; sine_rom[11] = 8'd10;
        sine_rom[12] = 8'd0;  sine_rom[13] = 8'd10; sine_rom[14] = 8'd37; sine_rom[15] = 8'd79;
    end
    
    // 相位累加器逻辑
    always @(posedge clk) begin
        if (rst)
            phase_accum <= 0;
        else
            phase_accum <= phase_accum + phase_incr;
    end
    
    // 提前计算ROM地址，分离关键路径
    always @(posedge clk) begin
        rom_addr <= phase_accum[PHASE_WIDTH-1:PHASE_WIDTH-4];
    end
    
    // 注册输出以降低关键路径延迟
    always @(posedge clk) begin
        sine_wave <= sine_rom[rom_addr];
    end
endmodule