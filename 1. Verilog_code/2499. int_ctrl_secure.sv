module int_ctrl_secure #(
    parameter DOMAINS = 2
)(
    input clk, rst,
    input [DOMAINS-1:0] domain_en,
    input [15:0] intr_vec,
    output reg [3:0] secure_grant
);
    // 改为明确的位宽扩展
    wire [15:0] domain_mask;
    assign domain_mask = {16{|domain_en}};
    wire [15:0] masked_intr = intr_vec & domain_mask;
    
    // 添加编码器函数
    function [3:0] encoder;
        input [15:0] value;
        begin
            casez(value)
                16'b1???????????????: encoder = 4'd15;
                16'b01??????????????: encoder = 4'd14;
                16'b001?????????????: encoder = 4'd13;
                16'b0001????????????: encoder = 4'd12;
                16'b00001???????????: encoder = 4'd11;
                16'b000001??????????: encoder = 4'd10;
                16'b0000001?????????: encoder = 4'd9;
                16'b00000001????????: encoder = 4'd8;
                16'b000000001???????: encoder = 4'd7;
                16'b0000000001??????: encoder = 4'd6;
                16'b00000000001?????: encoder = 4'd5;
                16'b000000000001????: encoder = 4'd4;
                16'b0000000000001???: encoder = 4'd3;
                16'b00000000000001??: encoder = 4'd2;
                16'b000000000000001?: encoder = 4'd1;
                16'b0000000000000001: encoder = 4'd0;
                default: encoder = 4'd0;
            endcase
        end
    endfunction
    
    always @(posedge clk)
        secure_grant <= encoder(masked_intr);
endmodule