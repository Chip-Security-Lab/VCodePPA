//SystemVerilog
module int_ctrl_group #(GROUPS=2, WIDTH=4)(
    input clk, rst,
    input [GROUPS*WIDTH-1:0] int_in,
    input [GROUPS-1:0] group_en,
    output [GROUPS-1:0] group_int
);
    genvar g, i, j, s;
    generate
        for(g=0; g<GROUPS; g=g+1) begin: group_logic
            wire [WIDTH-1:0] group_signals;
            
            // Extract group signals
            for(i=0; i<WIDTH; i=i+1) begin: signal_extract
                assign group_signals[i] = int_in[g*WIDTH+i];
            end
            
            // Implementation using parallel prefix adder algorithm
            wire [WIDTH-1:0] p;           // Propagate signals
            wire [WIDTH-1:0][WIDTH-1:0] pp; // Parallel prefix signals
            
            // Stage 0: Initialize propagate signals
            for(i=0; i<WIDTH; i=i+1) begin: init_stage
                assign p[i] = group_signals[i];
                assign pp[0][i] = p[i];
            end
            
            // Parallel prefix computation - Kogge-Stone algorithm
            for(s=1; s<$clog2(WIDTH)+1; s=s+1) begin: prefix_stages
                localparam STEP = 2**(s-1);
                for(i=0; i<WIDTH; i=i+1) begin: prefix_ops
                    if(i >= STEP) begin
                        assign pp[s][i] = pp[s-1][i] | pp[s-1][i-STEP];
                    end else begin
                        assign pp[s][i] = pp[s-1][i];
                    end
                end
            end
            
            // Final output gated with enable
            wire final_result = pp[$clog2(WIDTH)][WIDTH-1];
            assign group_int[g] = final_result & group_en[g];
        end
    endgenerate
endmodule