//SystemVerilog
// 顶层模块
module nonlinear_quant #(
    parameter IN_W     = 8,
    parameter OUT_W    = 4,
    parameter LUT_SIZE = 16
) (
    input                  clk,
    input      [IN_W-1:0]  data_in,
    output     [OUT_W-1:0] quant_out
);
    wire [$clog2(LUT_SIZE)-1:0] lut_index;
    reg  [IN_W-1:0] data_in_reg;
    
    // 寄存器移到输入端
    always @(posedge clk) begin
        data_in_reg <= data_in;
    end
    
    // 地址生成器实例化
    address_generator #(
        .IN_W(IN_W),
        .LUT_SIZE(LUT_SIZE)
    ) addr_gen (
        .data_in(data_in_reg),
        .lut_index(lut_index)
    );
    
    // 查找表存储和访问实例化
    lut_memory #(
        .OUT_W(OUT_W),
        .LUT_SIZE(LUT_SIZE),
        .IN_W(IN_W)
    ) lut_mem (
        .clk(clk),
        .lut_index(lut_index),
        .quant_out(quant_out)
    );
endmodule

// 地址生成器子模块
module address_generator #(
    parameter IN_W     = 8,
    parameter LUT_SIZE = 16
) (
    input      [IN_W-1:0]              data_in,
    output     [$clog2(LUT_SIZE)-1:0]  lut_index
);
    // 组合逻辑计算索引
    // 假设我们使用输入的高位作为查找表索引
    assign lut_index = data_in[IN_W-1:IN_W-$clog2(LUT_SIZE)];
endmodule

// 查找表存储和访问子模块
module lut_memory #(
    parameter OUT_W    = 4,
    parameter LUT_SIZE = 16,
    parameter IN_W     = 8
) (
    input                              clk,
    input      [$clog2(LUT_SIZE)-1:0]  lut_index,
    output reg [OUT_W-1:0]             quant_out
);
    reg [OUT_W-1:0] lut [0:LUT_SIZE-1];
    
    integer i;
    initial begin
        i = 0;
        while (i < LUT_SIZE) begin
            lut[i] = ((i*i) >> (IN_W - OUT_W));
            i = i + 1;
        end
    end
    
    always @(posedge clk) begin
        quant_out <= lut[lut_index];
    end
endmodule