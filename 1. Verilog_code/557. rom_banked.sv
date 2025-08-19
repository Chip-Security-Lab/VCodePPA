module rom_banked #(parameter BANKS=4, DW=16)(
    input [1:0] bank_sel,
    input [6:0] addr,
    output reg [DW-1:0] data
);
    // 声明存储器
    reg [DW-1:0] bank0 [0:127];
    reg [DW-1:0] bank1 [0:127];
    reg [DW-1:0] bank2 [0:127];
    reg [DW-1:0] bank3 [0:127];
    
    // 初始化一些简单值用于测试
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            bank0[i] = i;
            bank1[i] = i + 128;
            bank2[i] = i + 256;
            bank3[i] = i + 384;
        end
    end
    
    // 使用always块和case代替三元运算符
    always @(*) begin
        case(bank_sel)
            2'b00: data = bank0[addr];
            2'b01: data = bank1[addr];
            2'b10: data = bank2[addr];
            2'b11: data = bank3[addr];
            default: data = bank0[addr];
        endcase
    end
endmodule