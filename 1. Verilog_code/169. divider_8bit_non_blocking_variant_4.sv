//SystemVerilog
module divider_8bit_non_blocking (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);

    // 优化的查找表除法器实例
    optimized_divider divider_inst (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module optimized_divider (
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // 优化的查找表ROM
    reg [7:0] lut_rom [0:255];
    reg [7:0] lut_addr;
    reg [7:0] lut_data;
    
    // 优化的查找表初始化
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            lut_rom[i] = i;
        end
    end

    // 优化的查找表地址和数据读取
    always @(*) begin
        lut_addr = dividend;
        lut_data = lut_rom[lut_addr];
    end

    // 优化的除法运算核心逻辑
    always @(*) begin
        if (divisor == 8'd0) begin
            {quotient, remainder} = {8'hFF, 8'hFF};
        end else begin
            quotient = lut_data / divisor;
            remainder = lut_data - (quotient * divisor);
        end
    end

endmodule