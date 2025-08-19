//SystemVerilog
module shadow_reg #(parameter DW=16) (
    input wire clk,      // 时钟信号
    input wire en,       // 使能信号
    input wire commit,   // 提交信号
    input wire [DW-1:0] din,    // 数据输入
    output wire [DW-1:0] dout    // 数据输出
);
    reg [DW-1:0] din_reg;        // 输入寄存器
    reg en_reg, commit_reg;      // 控制信号寄存器
    reg [DW-1:0] shadow_reg;     // 影子寄存器
    
    // 对输入信号进行寄存
    always @(posedge clk) begin
        din_reg <= din;
        en_reg <= en;
        commit_reg <= commit;
    end
    
    // 更新影子寄存器
    always @(posedge clk) begin
        if(en_reg) shadow_reg <= din_reg;
        else if(commit_reg) shadow_reg <= shadow_reg;
    end
    
    // 使用连续赋值将shadow_reg连接到输出
    assign dout = shadow_reg;
    
endmodule