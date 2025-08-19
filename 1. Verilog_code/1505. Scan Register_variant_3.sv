//SystemVerilog
// IEEE 1364-2005 Verilog标准
module scan_register #(parameter WIDTH = 8) (
    input wire scan_clk, scan_rst, scan_en, test_mode,
    input wire scan_in,
    input wire [WIDTH-1:0] data_in,
    output wire scan_out,
    output wire [WIDTH-1:0] data_out
);
    // 主扫描寄存器
    reg [WIDTH-1:0] scan_reg;
    // 用于扫描操作的内部信号
    reg scan_shift_enable;
    reg data_load_enable;
    
    // 控制信号生成块 - 决定操作模式
    always @(*) begin
        scan_shift_enable = test_mode && scan_en;
        data_load_enable = !test_mode;
    end
    
    // 重置控制块 - 处理复位逻辑
    always @(posedge scan_clk) begin
        if (scan_rst)
            scan_reg <= {WIDTH{1'b0}};
    end
    
    // 扫描移位块 - 处理扫描测试模式
    always @(posedge scan_clk) begin
        if (!scan_rst && scan_shift_enable)
            scan_reg <= {scan_reg[WIDTH-2:0], scan_in};
    end
    
    // 数据加载块 - 处理功能模式数据
    always @(posedge scan_clk) begin
        if (!scan_rst && data_load_enable)
            scan_reg <= data_in;
    end
    
    // 输出赋值
    assign scan_out = scan_reg[WIDTH-1];
    assign data_out = scan_reg;
endmodule