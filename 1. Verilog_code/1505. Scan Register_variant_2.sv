//SystemVerilog - IEEE 1364-2005
module scan_register #(parameter WIDTH = 8) (
    input  wire           scan_clk,   // 扫描时钟
    input  wire           scan_rst,   // 扫描复位
    input  wire           scan_en,    // 扫描使能
    input  wire           test_mode,  // 测试模式选择
    input  wire           scan_in,    // 扫描输入
    input  wire [WIDTH-1:0] data_in,  // 功能数据输入
    output wire           scan_out,   // 扫描输出
    output wire [WIDTH-1:0] data_out  // 功能数据输出
);
    // 核心扫描寄存器
    reg [WIDTH-1:0] scan_reg_stage1;
    // 分段扫描输出寄存器，提高时序裕量
    reg             scan_out_stage1;
    reg             scan_out_stage2;
    
    // 输入复用阶段 - 数据通路第一级
    reg [WIDTH-1:0] input_mux_data;
    reg             input_scan_bit;
    
    // 输入复用逻辑 - 将组合逻辑与时序分离
    always @(*) begin
        if (test_mode && scan_en) begin
            input_mux_data = {scan_reg_stage1[WIDTH-2:0], scan_in};
            input_scan_bit = scan_reg_stage1[WIDTH-1];
        end
        else begin
            input_mux_data = data_in;
            input_scan_bit = data_in[WIDTH-1];
        end
    end
    
    // 寄存器阶段 - 数据通路第二级
    always @(posedge scan_clk) begin
        if (scan_rst) begin
            scan_reg_stage1 <= {WIDTH{1'b0}};
            scan_out_stage1 <= 1'b0;
        end
        else begin
            scan_reg_stage1 <= input_mux_data;
            scan_out_stage1 <= input_scan_bit;
        end
    end
    
    // 输出寄存器阶段 - 数据通路第三级
    always @(posedge scan_clk) begin
        if (scan_rst) begin
            scan_out_stage2 <= 1'b0;
        end
        else begin
            scan_out_stage2 <= scan_out_stage1;
        end
    end
    
    // 输出赋值
    assign scan_out = scan_out_stage2;
    assign data_out = scan_reg_stage1;
    
endmodule