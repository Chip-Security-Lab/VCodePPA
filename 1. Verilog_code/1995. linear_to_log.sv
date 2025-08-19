module linear_to_log #(parameter WIDTH=8, LUT_SIZE=16)(
    input wire [WIDTH-1:0] linear_in,
    output reg [WIDTH-1:0] log_out
);
    integer i, best_idx;
    reg [WIDTH-1:0] min_diff;
    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];
    
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = (1 << (i/2)); // 简化的指数算法
        end
    end
    
    always @* begin
        best_idx = 0;
        min_diff = {WIDTH{1'b1}};
        
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            if (linear_in >= lut[i] && (linear_in - lut[i]) < min_diff) begin
                min_diff = linear_in - lut[i];
                best_idx = i;
            end
        end
        
        log_out = best_idx[WIDTH-1:0];
    end
endmodule