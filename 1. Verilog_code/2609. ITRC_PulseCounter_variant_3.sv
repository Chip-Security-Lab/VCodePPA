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
    
    // Manchester carry chain signals
    wire [3:0] carry [0:WIDTH-1];
    wire [3:0] sum [0:WIDTH-1];
    
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_counter
            // Manchester carry chain implementation
            wire [3:0] g, p;
            
            // Generate and propagate signals
            assign g = int_in[i] ? counters[i] : 4'b0;
            assign p = int_in[i] ? 4'b1 : 4'b0;
            
            // First stage carry chain
            wire [3:0] carry_stage1;
            assign carry_stage1[0] = g[0];
            assign carry_stage1[1] = g[1] | (p[1] & carry_stage1[0]);
            assign carry_stage1[2] = g[2] | (p[2] & carry_stage1[1]);
            assign carry_stage1[3] = g[3] | (p[3] & carry_stage1[2]);
            
            // Second stage carry chain
            wire [3:0] carry_stage2;
            assign carry_stage2[0] = carry_stage1[0];
            assign carry_stage2[1] = carry_stage1[1];
            assign carry_stage2[2] = carry_stage1[2] | (p[2] & carry_stage1[0]);
            assign carry_stage2[3] = carry_stage1[3] | (p[3] & carry_stage1[1]);
            
            // Final carry chain
            assign carry[i][0] = carry_stage2[0];
            assign carry[i][1] = carry_stage2[1];
            assign carry[i][2] = carry_stage2[2];
            assign carry[i][3] = carry_stage2[3] | (p[3] & carry_stage2[0]);
            
            // Sum calculation
            assign sum[i][0] = p[0];
            assign sum[i][1] = p[1] ^ carry[i][0];
            assign sum[i][2] = p[2] ^ carry[i][1];
            assign sum[i][3] = p[3] ^ carry[i][2];
            
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