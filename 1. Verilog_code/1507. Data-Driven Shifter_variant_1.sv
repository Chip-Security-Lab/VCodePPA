//SystemVerilog
// IEEE 1364-2005 Verilog标准
module data_driven_shifter #(parameter WIDTH = 8) (
    input wire clk, rst,
    input wire data_valid,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out,
    // 新增减法器接口
    input wire subtract_en,
    input wire [WIDTH-1:0] minuend,
    input wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] difference
);
    // 流水线级寄存器 - 移位部分
    reg [WIDTH-1:0] shift_data_stage1;
    
    // 流水线级寄存器和控制信号 - 减法部分
    reg subtract_en_stage1, subtract_en_stage2;
    reg [WIDTH-1:0] minuend_stage1, minuend_stage2;
    reg [WIDTH-1:0] complement_stage1;
    reg [WIDTH-1:0] subtraction_result_stage2;
    
    // Stage 1: 数据接收和预处理
    always @(posedge clk) begin
        if (rst) begin
            shift_data_stage1 <= 0;
            subtract_en_stage1 <= 0;
            minuend_stage1 <= 0;
            complement_stage1 <= 0;
        end
        else begin
            // 移位寄存器逻辑
            if (data_valid)
                shift_data_stage1 <= {shift_data_stage1[WIDTH-2:0], serial_in};
                
            // 减法预处理 - 计算补码并存储到流水线寄存器
            subtract_en_stage1 <= subtract_en;
            minuend_stage1 <= minuend;
            complement_stage1 <= ~subtrahend + 1'b1; // 生成二进制补码
        end
    end
    
    // Stage 2: 减法执行阶段
    always @(posedge clk) begin
        if (rst) begin
            subtract_en_stage2 <= 0;
            minuend_stage2 <= 0;
            subtraction_result_stage2 <= 0;
        end
        else begin
            // 传递控制信号
            subtract_en_stage2 <= subtract_en_stage1;
            minuend_stage2 <= minuend_stage1;
            
            // 执行减法运算
            if (subtract_en_stage1)
                subtraction_result_stage2 <= minuend_stage1 + complement_stage1;
        end
    end
    
    // 输出分配
    assign parallel_out = shift_data_stage1;
    assign difference = subtraction_result_stage2;
endmodule