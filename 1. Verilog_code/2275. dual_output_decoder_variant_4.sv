//SystemVerilog
module dual_output_decoder(
    input [2:0] binary_in,
    output reg [7:0] onehot_out,
    output reg [2:0] gray_out
);
    // 使用Booth乘法算法实现8位乘法
    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg [15:0] product;
    reg [7:0] booth_encoded;
    reg [2:0] i;
    reg [8:0] partial_product;
    
    always @(*) begin
        // 初始化为零
        product = 16'b0;
        multiplier = {5'b0, binary_in};
        multiplicand = 8'b00000001;
        
        // Booth编码乘法算法实现
        for (i = 0; i < 3'b100; i = i + 1) begin
            case({multiplier[1:0], 1'b0})
                3'b000, 3'b111: booth_encoded = 8'b0; // +0
                3'b001, 3'b010: booth_encoded = multiplicand; // +M
                3'b011: booth_encoded = {multiplicand[6:0], 1'b0}; // +2M
                3'b100: booth_encoded = {~multiplicand[6:0], 1'b0} + 1'b1; // -2M
                3'b101, 3'b110: booth_encoded = ~multiplicand + 1'b1; // -M
                default: booth_encoded = 8'b0;
            endcase
            
            // 扩展符号位，计算部分积
            partial_product = {booth_encoded[7], booth_encoded};
            
            // 累加部分积
            product = product + (partial_product << (i*2));
            
            // 右移乘数
            multiplier = multiplier >> 2;
        end
        
        // 映射输出
        case(binary_in)
            3'b000: onehot_out = 8'b00000001;
            3'b001: onehot_out = 8'b00000010;
            3'b010: onehot_out = 8'b00000100;
            3'b011: onehot_out = 8'b00001000;
            3'b100: onehot_out = 8'b00010000;
            3'b101: onehot_out = 8'b00100000;
            3'b110: onehot_out = 8'b01000000;
            3'b111: onehot_out = 8'b10000000;
            default: onehot_out = 8'b00000000;
        endcase
        
        // Convert to Gray code
        gray_out[2] = binary_in[2];
        gray_out[1] = binary_in[2] ^ binary_in[1];
        gray_out[0] = binary_in[1] ^ binary_in[0];
    end
endmodule