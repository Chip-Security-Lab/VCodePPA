//SystemVerilog
module parity_decoder(
    input [2:0] addr,
    input parity_bit,
    output reg [7:0] select,
    output reg parity_error
);
    // 异或计算预期的奇偶校验位
    wire expected_parity;
    assign expected_parity = ^addr;
    
    // 生成桶形移位器结构的所有可能输出
    wire [7:0] barrel_outputs [0:7];
    assign barrel_outputs[0] = 8'b00000001;
    assign barrel_outputs[1] = 8'b00000010;
    assign barrel_outputs[2] = 8'b00000100;
    assign barrel_outputs[3] = 8'b00001000;
    assign barrel_outputs[4] = 8'b00010000;
    assign barrel_outputs[5] = 8'b00100000;
    assign barrel_outputs[6] = 8'b01000000;
    assign barrel_outputs[7] = 8'b10000000;
    
    always @(*) begin
        // 校验奇偶校验位
        parity_error = (expected_parity != parity_bit);
        
        if (parity_error) begin
            select = 8'b0;
        end else begin
            // 使用地址作为多路复用器选择信号，实现桶形移位
            select = barrel_outputs[addr];
        end
    end
endmodule