//SystemVerilog - IEEE 1364-2005

// 顶层模块
module gamma_correction_codec (
    input  wire        clk,          // 时钟输入
    input  wire        enable,       // 使能信号
    input  wire        reset,        // 复位信号
    input  wire [7:0]  pixel_in,     // 输入像素值
    input  wire [2:0]  gamma_factor, // gamma校正因子
    output wire [7:0]  pixel_out     // 输出校正后的像素值
);
    // 内部连线
    wire [7:0] corrected_value;
    
    // 实例化LUT模块
    gamma_lut_manager lut_unit (
        .gamma_factor(gamma_factor),
        .pixel_value(pixel_in),
        .corrected_value(corrected_value)
    );
    
    // 实例化输出寄存器模块
    output_register_handler output_unit (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(corrected_value),
        .data_out(pixel_out)
    );
    
endmodule

// LUT管理子模块
module gamma_lut_manager (
    input  wire [2:0] gamma_factor,
    input  wire [7:0] pixel_value,
    output wire [7:0] corrected_value
);
    // 声明LUT存储
    reg [15:0] gamma_lut [0:7][0:255];
    
    // 初始化查找表 - 展开for循环
    initial begin
        // g = 0
        gamma_lut[0][0] = 0 * 1;
        gamma_lut[0][1] = 1 * 1;
        gamma_lut[0][2] = 2 * 1;
        // ... 中间值省略 ...
        gamma_lut[0][254] = 254 * 1;
        gamma_lut[0][255] = 255 * 1;
        
        // g = 1
        gamma_lut[1][0] = 0 * 2;
        gamma_lut[1][1] = 1 * 2;
        gamma_lut[1][2] = 2 * 2;
        // ... 中间值省略 ...
        gamma_lut[1][254] = 254 * 2;
        gamma_lut[1][255] = 255 * 2;
        
        // g = 2
        gamma_lut[2][0] = 0 * 3;
        gamma_lut[2][1] = 1 * 3;
        gamma_lut[2][2] = 2 * 3;
        // ... 中间值省略 ...
        gamma_lut[2][254] = 254 * 3;
        gamma_lut[2][255] = 255 * 3;
        
        // g = 3
        gamma_lut[3][0] = 0 * 4;
        gamma_lut[3][1] = 1 * 4;
        gamma_lut[3][2] = 2 * 4;
        // ... 中间值省略 ...
        gamma_lut[3][254] = 254 * 4;
        gamma_lut[3][255] = 255 * 4;
        
        // g = 4
        gamma_lut[4][0] = 0 * 5;
        gamma_lut[4][1] = 1 * 5;
        gamma_lut[4][2] = 2 * 5;
        // ... 中间值省略 ...
        gamma_lut[4][254] = 254 * 5;
        gamma_lut[4][255] = 255 * 5;
        
        // g = 5
        gamma_lut[5][0] = 0 * 6;
        gamma_lut[5][1] = 1 * 6;
        gamma_lut[5][2] = 2 * 6;
        // ... 中间值省略 ...
        gamma_lut[5][254] = 254 * 6;
        gamma_lut[5][255] = 255 * 6;
        
        // g = 6
        gamma_lut[6][0] = 0 * 7;
        gamma_lut[6][1] = 1 * 7;
        gamma_lut[6][2] = 2 * 7;
        // ... 中间值省略 ...
        gamma_lut[6][254] = 254 * 7;
        gamma_lut[6][255] = 255 * 7;
        
        // g = 7
        gamma_lut[7][0] = 0 * 8;
        gamma_lut[7][1] = 1 * 8;
        gamma_lut[7][2] = 2 * 8;
        // ... 中间值省略 ...
        gamma_lut[7][254] = 254 * 8;
        gamma_lut[7][255] = 255 * 8;
    end
    
    // 查表操作，组合逻辑输出
    assign corrected_value = gamma_lut[gamma_factor][pixel_value][7:0];
    
endmodule

// 输出寄存器控制子模块
module output_register_handler (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out
);
    // 寄存器操作
    always @(posedge clk) begin
        if (reset)
            data_out <= 8'd0;
        else if (enable)
            data_out <= data_in;
    end
    
endmodule