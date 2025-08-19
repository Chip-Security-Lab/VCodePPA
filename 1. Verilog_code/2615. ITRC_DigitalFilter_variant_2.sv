//SystemVerilog
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
    reg [WIDTH-1:0] temp_filtered;
    integer i;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= 0;
            filtered_int <= 0;
        end else begin
            shift_reg[0] <= noisy_int;
            for (i=1; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= shift_reg[i-1];
            
            // 使用位运算优化比较逻辑
            temp_filtered = shift_reg[0] & shift_reg[1] & shift_reg[2];
            filtered_int <= temp_filtered;
        end
    end
endmodule