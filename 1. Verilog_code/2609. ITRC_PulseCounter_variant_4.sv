//SystemVerilog
module ITRC_PulseCounter #(
    parameter WIDTH = 8,
    parameter THRESHOLD = 5
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg int_out
);
    reg [3:0] counters [0:WIDTH-1];
    genvar i;
    reg [WIDTH-1:0] threshold_met;
    integer j;
    
    // 带状进位加法器相关信号
    wire [WIDTH-1:0] carry_in;
    wire [WIDTH-1:0] carry_out;
    wire [WIDTH-1:0] sum;
    
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_counter
            // 带状进位加法器实现
            assign carry_in[i] = (i == 0) ? 1'b0 : carry_out[i-1];
            assign {carry_out[i], sum[i]} = counters[i] + int_in[i] + carry_in[i];
            
            always @(posedge clk) begin
                if (!rst_n) 
                    counters[i] <= 0;
                else if (int_in[i])
                    counters[i] <= (counters[i] < THRESHOLD) ? sum[i] : counters[i];
                else
                    counters[i] <= 0;
            end
            
            always @(*) begin
                threshold_met[i] = (counters[i] >= THRESHOLD);
            end
        end
    endgenerate
    
    always @(*) begin
        int_out = |threshold_met;
    end
endmodule