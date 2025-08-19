//SystemVerilog
module bus_width_display_codec #(
    parameter INBUS_WIDTH = 32,
    parameter OUTBUS_WIDTH = 16
) (
    input clk, rst_n,
    input clk_en,  // Clock gating control
    input [INBUS_WIDTH-1:0] data_in,
    input [1:0] format_select,  // 0: RGB, 1: YUV, 2: MONO, 3: RAW
    output reg [OUTBUS_WIDTH-1:0] data_out
);
    // 内部信号定义
    wire gated_clk;
    reg [INBUS_WIDTH-1:0] data_in_reg;
    reg [1:0] format_select_reg;
    
    // 数据处理阶段信号
    reg [OUTBUS_WIDTH-1:0] rgb_data;
    reg [OUTBUS_WIDTH-1:0] yuv_data;
    reg [OUTBUS_WIDTH-1:0] mono_data;
    reg [OUTBUS_WIDTH-1:0] raw_data;
    reg [OUTBUS_WIDTH-1:0] processed_data;
    
    // 高效时钟门控 - 使用标准模式
    assign gated_clk = clk & clk_en;
    
    // 第一级流水线：输入数据寄存和格式选择
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {INBUS_WIDTH{1'b0}};
            format_select_reg <= 2'b00;
        end else begin
            data_in_reg <= data_in;
            format_select_reg <= format_select;
        end
    end
    
    // 第二级流水线：优化的并行处理各种格式转换
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_data <= {OUTBUS_WIDTH{1'b0}};
            yuv_data <= {OUTBUS_WIDTH{1'b0}};
            mono_data <= {OUTBUS_WIDTH{1'b0}};
            raw_data <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            // 优化的RGB处理路径
            if (INBUS_WIDTH >= 24 && OUTBUS_WIDTH >= 16) begin
                // 优化位域提取 - 直接进行位置映射
                rgb_data <= {
                    data_in_reg[INBUS_WIDTH-1:INBUS_WIDTH-5],                    // R分量 (5位)
                    data_in_reg[INBUS_WIDTH-9:INBUS_WIDTH-14],                   // G分量 (6位)
                    data_in_reg[INBUS_WIDTH-17:INBUS_WIDTH-21],                  // B分量 (5位)
                    {(OUTBUS_WIDTH > 16) ? (OUTBUS_WIDTH-16) : 0{1'b0}}          // 剩余位填充
                };
            end else begin
                rgb_data <= data_in_reg[INBUS_WIDTH-1-:OUTBUS_WIDTH];            // 优化的位选择语法
            end
            
            // 简化的YUV处理路径
            yuv_data <= data_in_reg[INBUS_WIDTH-1-:OUTBUS_WIDTH];
            
            // 优化的MONO处理路径 - 位复制而非逐位赋值
            mono_data <= {OUTBUS_WIDTH{data_in_reg[INBUS_WIDTH-1]}};
            
            // 优化的RAW处理路径
            raw_data <= data_in_reg[INBUS_WIDTH-1-:OUTBUS_WIDTH];                // 使用部分选择操作符
        end
    end
    
    // 第三级流水线：优化的格式选择逻辑
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_data <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            // 使用优化的比较结构 - 参数化多路复用器
            processed_data <= 
                ({OUTBUS_WIDTH{~|format_select_reg[1:0]}} & rgb_data) |           // 00: RGB
                ({OUTBUS_WIDTH{format_select_reg[0] & ~format_select_reg[1]}} & yuv_data) |  // 01: YUV
                ({OUTBUS_WIDTH{format_select_reg[1] & ~format_select_reg[0]}} & mono_data) | // 10: MONO
                ({OUTBUS_WIDTH{&format_select_reg[1:0]}} & raw_data);              // 11: RAW
        end
    end
    
    // 输出注册阶段
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            data_out <= processed_data;
        end
    end
    
endmodule