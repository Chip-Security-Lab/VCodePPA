module float_normalizer #(
    parameter INT_WIDTH = 16,
    parameter EXP_WIDTH = 5,
    parameter FRAC_WIDTH = 10
)(
    input [INT_WIDTH-1:0] int_in,
    output [EXP_WIDTH+FRAC_WIDTH-1:0] float_out,
    output reg overflow
);
    reg [EXP_WIDTH-1:0] exponent;
    reg [FRAC_WIDTH-1:0] fraction;
    integer i, leading_pos;
    
    always @(*) begin
        // 寻找最高位的1
        leading_pos = -1;
        overflow = 0;
        
        for (i = INT_WIDTH-1; i >= 0; i = i - 1)
            if (int_in[i] && leading_pos == -1)
                leading_pos = i;
        
        if (leading_pos == -1) begin
            // 输入为0
            exponent = 0;
            fraction = 0;
        end else if (leading_pos >= FRAC_WIDTH) begin
            exponent = leading_pos;
            fraction = int_in[leading_pos-1 -: FRAC_WIDTH];
        end else begin
            exponent = leading_pos;
            fraction = int_in << (FRAC_WIDTH - leading_pos);
        end
        
        // 检查指数是否溢出
        if (leading_pos >= (1 << EXP_WIDTH))
            overflow = 1;
    end
    
    assign float_out = {exponent, fraction};
endmodule