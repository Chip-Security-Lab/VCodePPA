//SystemVerilog
module enc_8b10b (
    input  wire [7:0] data_in,
    output reg  [9:0] encoded
);

    // 移位累加乘法器子模块
    function [9:0] shift_add_mult_10bit;
        input [9:0] operand_a;
        input [9:0] operand_b;
        integer i;
        reg [19:0] product;
        begin
            product = 20'd0;
            for (i = 0; i < 10; i = i + 1) begin
                if (operand_b[i])
                    product = product + (operand_a << i);
            end
            shift_add_mult_10bit = product[9:0];
        end
    endfunction

    reg [9:0] encoded_val_0;
    reg [9:0] encoded_val_1;
    reg [9:0] temp_result;

    always @* begin
        // 用移位累加乘法器生成编码值
        // 直接赋值替换为移位累加乘法器形式
        encoded_val_0 = shift_add_mult_10bit(10'b1001110100, 10'b0000000001); // 乘以1
        encoded_val_1 = shift_add_mult_10bit(10'b0111010100, 10'b0000000001); // 乘以1
        temp_result = shift_add_mult_10bit(10'b0000000000, 10'b0000000001);   // 乘以1
        if (data_in == 8'h00) begin
            encoded = encoded_val_0;
        end else if (data_in == 8'h01) begin
            encoded = encoded_val_1;
        end else begin
            encoded = temp_result;
        end
    end

endmodule