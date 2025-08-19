//SystemVerilog
module ITRC_PeriodicGen #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output reg int_out
);
    reg [$clog2(PERIOD):0] counter;
    
    // Parallel prefix adder signals
    wire [$clog2(PERIOD):0] counter_next;
    wire [$clog2(PERIOD):0] g, p;
    wire [$clog2(PERIOD):0] carry;
    
    // Generate and propagate signals
    assign g = counter & 1'b1;
    assign p = counter ^ 1'b1;
    
    // Carry computation using parallel prefix
    assign carry[0] = g[0];
    assign carry[1] = g[1] | (p[1] & g[0]);
    assign carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign carry[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]);
    assign carry[5] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign carry[6] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign carry[7] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    
    // Sum computation
    assign counter_next = p ^ carry;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            int_out <= 0;
        end else if (en) begin
            if (counter == PERIOD-1) begin
                int_out <= 1;
                counter <= 0;
            end else begin
                int_out <= 0;
                counter <= counter_next;
            end
        end
    end
endmodule