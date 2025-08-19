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
    wire [WIDTH-1:0] threshold_met;
    wire [WIDTH-1:0] count_enable;
    wire [WIDTH-1:0] count_reset;
    
    // 优化的计数器使能和复位逻辑
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_counter
            // 使用组合逻辑优化计数器控制
            assign count_enable[i] = int_in[i] & (counters[i] < THRESHOLD);
            assign count_reset[i] = ~int_in[i] | (counters[i] >= THRESHOLD);
            
            // 优化的计数器逻辑
            always @(posedge clk) begin
                if (!rst_n)
                    counters[i] <= 0;
                else if (count_reset[i])
                    counters[i] <= 0;
                else if (count_enable[i])
                    counters[i] <= counters[i] + 1'b1;
            end
            
            // 优化的阈值检测
            assign threshold_met[i] = (counters[i] >= THRESHOLD);
        end
    endgenerate
    
    // 优化的输出逻辑
    always @(*) begin
        int_out = |threshold_met;
    end

endmodule