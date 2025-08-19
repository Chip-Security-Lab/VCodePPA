//SystemVerilog
module dram_write_leveling #(
    parameter DQ_BITS = 8
)(
    input clk,
    input training_en,
    output reg [DQ_BITS-1:0] dqs_pattern
);

    // Pipeline Stage 1: Counter and Pattern Generation
    reg [7:0] phase_counter;
    wire [7:0] phase_counter_next;
    wire [7:0] pattern_gen;
    
    // Pipeline Stage 2: Adder Implementation
    wire [7:0] g, p;
    wire [7:0] g_level1, p_level1;
    wire [7:0] g_level2, p_level2;
    wire [7:0] g_level3, p_level3;
    wire [7:0] sum;
    
    // Generate and Propagate Calculation
    assign g = phase_counter & 8'h01;
    assign p = phase_counter ^ 8'h01;
    
    // Level 1: First Stage Carry Lookahead
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    
    // Level 2: Second Stage Carry Lookahead
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g[2] | (p[2] & g_level1[1]);
    assign p_level2[2] = p[2] & p_level1[1];
    assign g_level2[3] = g[3] | (p[3] & g_level1[1]);
    assign p_level2[3] = p[3] & p_level1[1];
    
    // Level 3: Final Stage Carry Lookahead
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    assign g_level3[4] = g[4] | (p[4] & g_level2[3]);
    assign p_level3[4] = p[4] & p_level2[3];
    assign g_level3[5] = g[5] | (p[5] & g_level2[3]);
    assign p_level3[5] = p[5] & p_level2[3];
    assign g_level3[6] = g[6] | (p[6] & g_level2[3]);
    assign p_level3[6] = p[6] & p_level2[3];
    assign g_level3[7] = g[7] | (p[7] & g_level2[3]);
    assign p_level3[7] = p[7] & p_level2[3];
    
    // Sum Calculation with Registered Output
    reg [7:0] sum_reg;
    assign sum[0] = p[0] ^ 1'b0;
    assign sum[1] = p[1] ^ g_level1[0];
    assign sum[2] = p[2] ^ g_level2[1];
    assign sum[3] = p[3] ^ g_level2[1];
    assign sum[4] = p[4] ^ g_level3[3];
    assign sum[5] = p[5] ^ g_level3[3];
    assign sum[6] = p[6] ^ g_level3[3];
    assign sum[7] = p[7] ^ g_level3[3];
    
    assign phase_counter_next = sum;
    
    // Pattern Generation Logic
    assign pattern_gen = {8{phase_counter[3]}};
    
    // Pipeline Register Stage
    always @(posedge clk) begin
        if(training_en) begin
            phase_counter <= phase_counter_next;
            dqs_pattern <= pattern_gen;
        end else begin
            dqs_pattern <= {DQ_BITS{1'b0}};
        end
    end
endmodule