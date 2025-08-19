//SystemVerilog
// IEEE 1364-2005 Verilog
module multi_shadow_reg #(
    parameter WIDTH = 8,
    parameter LEVELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire [1:0] shadow_select,
    output wire [WIDTH-1:0] shadow_out
);
    // 直接捕获输入数据，移除了输入端的寄存器延迟
    wire [WIDTH-1:0] main_data;
    wire capture_signal;
    wire [1:0] select_signal;
    
    // 直接使用输入信号，移除了第一级寄存
    assign main_data = data_in;
    assign capture_signal = capture;
    assign select_signal = shadow_select;
    
    // 重构的shadow寄存器数组
    reg [WIDTH-1:0] shadow_reg [0:LEVELS-1];
    reg [1:0] shadow_select_pipe;
    
    // 合并原来的两级shadow寄存器逻辑
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < LEVELS; i = i + 1) begin
                shadow_reg[i] <= 0;
            end
            shadow_select_pipe <= 0;
        end else begin
            if (capture_signal) begin
                shadow_reg[0] <= main_data;
                for (i = 1; i < LEVELS; i = i + 1)
                    shadow_reg[i] <= shadow_reg[i-1];
            end
            shadow_select_pipe <= select_signal;
        end
    end
    
    // 输出寄存器 - 保留以维持原有的时序特性
    reg [WIDTH-1:0] shadow_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out_reg <= 0;
        end else begin
            shadow_out_reg <= shadow_reg[shadow_select_pipe];
        end
    end
    
    // 最终输出
    assign shadow_out = shadow_out_reg;
endmodule