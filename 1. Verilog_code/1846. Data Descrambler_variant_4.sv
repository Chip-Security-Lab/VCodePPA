//SystemVerilog
module data_descrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire scrambled_in,
    input  wire [POLY_WIDTH-1:0] poly_taps,
    input  wire [POLY_WIDTH-1:0] seed_val,
    input  wire seed_load,
    output wire descrambled_out
);
    // 定义移位寄存器和反馈信号
    reg [POLY_WIDTH-1:0] shift_reg;
    wire tap_xor;
    reg [POLY_WIDTH-1:0] next_shift_reg;
    
    // 计算所有抽头位的XOR结果用于反馈
    assign tap_xor = ^(shift_reg & poly_taps);
    
    // 通过将输入与抽头输出进行XOR运算来解扰数据
    assign descrambled_out = scrambled_in ^ shift_reg[0];
    
    // 计算下一个移位寄存器状态
    always @(*) begin
        if (seed_load)
            next_shift_reg = seed_val;
        else
            next_shift_reg = {tap_xor, shift_reg[POLY_WIDTH-1:1]};
    end
    
    // 处理寄存器更新和复位
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {POLY_WIDTH{1'b1}};
        else
            shift_reg <= next_shift_reg;
    end
endmodule