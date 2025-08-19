//SystemVerilog
// IEEE 1364-2005
module scan_register #(parameter WIDTH = 8) (
    input wire scan_clk, scan_rst, scan_en, test_mode,
    input wire scan_in,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] subtrahend,
    output wire scan_out,
    output wire [WIDTH-1:0] data_out,
    output wire [WIDTH-1:0] diff_out
);
    reg [WIDTH-1:0] scan_reg;
    wire [WIDTH-1:0] difference;
    wire [WIDTH-1:0] next_scan_reg;
    wire [WIDTH-1:0] shifted_scan_reg;
    
    // 显式多路复用实现的移位操作
    assign shifted_scan_reg = {scan_reg[WIDTH-2:0], scan_in};
    
    // 显式多路复用器结构替代条件表达式
    assign next_scan_reg = scan_rst ? {WIDTH{1'b0}} : 
                           (test_mode ? 
                              (scan_en ? shifted_scan_reg : scan_reg) : 
                              data_in);
    
    // 更新扫描寄存器
    always @(posedge scan_clk) begin
        scan_reg <= next_scan_reg;
    end
    
    // 优化的减法器实例化
    optimized_subtractor #(.WIDTH(WIDTH)) subtractor (
        .minuend(scan_reg),
        .subtrahend(subtrahend),
        .difference(difference)
    );
    
    assign scan_out = scan_reg[WIDTH-1];
    assign data_out = scan_reg;
    assign diff_out = difference;
endmodule

// 优化的减法器模块
module optimized_subtractor #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] minuend,
    input wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] difference
);
    // 使用更高效的进位链结构
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p;
    wire [WIDTH-1:0] carry_selected;
    
    // 初始进位为1
    assign carry[0] = 1'b1;
    
    // 生成传播信号和计算进位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            // 计算传播信号 - 使用异或简化
            assign p[i] = minuend[i] ^ ~subtrahend[i];
            
            // 显式多路复用器实现的进位选择
            assign carry_selected[i] = ~subtrahend[i] & carry[i];
            assign carry[i+1] = minuend[i] ? 1'b1 : carry_selected[i];
            
            // 计算差值位
            assign difference[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule