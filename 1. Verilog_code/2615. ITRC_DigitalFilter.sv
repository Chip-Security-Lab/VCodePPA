module ITRC_DigitalFilter #(
    parameter WIDTH = 8,
    parameter FILTER_CYCLES = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] noisy_int,
    output reg [WIDTH-1:0] filtered_int
);
    reg [WIDTH-1:0] shift_reg [0:FILTER_CYCLES-1];
    integer i;
    genvar j;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= 0;
        end else begin
            shift_reg[0] <= noisy_int;
            for (i=1; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end
    
    // 使用generate块生成每个位的滤波逻辑
    generate
        for (j=0; j<WIDTH; j=j+1) begin : filter_bit
            always @(*) begin
                filtered_int[j] = shift_reg[0][j] & shift_reg[1][j] & shift_reg[2][j];
            end
        end
    endgenerate
endmodule