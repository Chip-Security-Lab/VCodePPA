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
    
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_counter
            always @(posedge clk) begin
                if (!rst_n) counters[i] <= 0;
                else if (int_in[i])
                    counters[i] <= (counters[i] < THRESHOLD) ? counters[i] + 1 : counters[i];
                else
                    counters[i] <= 0;
            end
            
            // 将阈值检测逻辑移出循环
            always @(*) begin
                threshold_met[i] = (counters[i] >= THRESHOLD);
            end
        end
    endgenerate
    
    // 使用组合逻辑检查任何计数器是否达到阈值
    always @(*) begin
        int_out = |threshold_met;
    end
endmodule