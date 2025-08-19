module log_to_linear #(parameter WIDTH=8, LUT_SIZE=16)(
    input wire [WIDTH-1:0] log_in,
    output reg [WIDTH-1:0] linear_out
);
    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];
    
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = (1 << (i/2)); // 简化的指数算法
        end
    end
    
    always @* begin
        linear_out = (log_in < LUT_SIZE) ? lut[log_in] : {WIDTH{1'b1}};
    end
endmodule