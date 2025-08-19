//SystemVerilog
module parity_decoder(
    input [2:0] addr,
    input parity_bit,
    output reg [7:0] select,
    output reg parity_error
);
    // 计算期望的奇偶校验位
    wire expected_parity;
    assign expected_parity = ^addr; // XOR of all bits

    // 桶形移位器的实现
    reg [7:0] barrel_shift_out;
    
    always @(*) begin
        // 计算奇偶校验错误
        parity_error = (expected_parity != parity_bit);
        
        // 桶形移位器结构实现
        case(addr)
            3'b000: barrel_shift_out = 8'b00000001;
            3'b001: barrel_shift_out = 8'b00000010;
            3'b010: barrel_shift_out = 8'b00000100;
            3'b011: barrel_shift_out = 8'b00001000;
            3'b100: barrel_shift_out = 8'b00010000;
            3'b101: barrel_shift_out = 8'b00100000;
            3'b110: barrel_shift_out = 8'b01000000;
            3'b111: barrel_shift_out = 8'b10000000;
            default: barrel_shift_out = 8'b00000000;
        endcase
        
        // 最终输出，使用if-else替代条件运算符
        if (parity_error) begin
            select = 8'b0;
        end else begin
            select = barrel_shift_out;
        end
    end
endmodule