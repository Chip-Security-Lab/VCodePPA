//SystemVerilog
module DeltaEncoder (
    input wire clk,
    input wire rst_n,
    input wire [15:0] din,
    output reg [15:0] dout
);

    reg [15:0] prev_value;
    wire [15:0] delta;
    wire [16:0] borrow; // 借位信号，比输入多一位
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 使用借位减法器实现减法
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : BORROW_SUB
            assign delta[i] = din[i] ^ prev_value[i] ^ borrow[i];
            assign borrow[i+1] = (~din[i] & prev_value[i]) | (~din[i] & borrow[i]) | (prev_value[i] & borrow[i]);
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 16'h0000;
            dout <= 16'h0000;
        end else begin
            prev_value <= din;
            dout <= delta;
        end
    end

endmodule