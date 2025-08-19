//SystemVerilog
module timeout_pattern_matcher #(parameter W = 8, TIMEOUT = 7) (
    input clk, rst_n,
    input [W-1:0] data, pattern,
    output reg match_valid, match_result
);
    reg [$clog2(TIMEOUT+1)-1:0] counter;
    reg current_match_reg;
    wire current_match = (data == pattern);
    
    // Han-Carlson adder signals
    wire [$clog2(TIMEOUT+1)-1:0] counter_next;
    wire [$clog2(TIMEOUT+1)-1:0] p, g;
    wire [$clog2(TIMEOUT+1)-1:0] p_even, g_even;
    wire [$clog2(TIMEOUT+1)-1:0] p_odd, g_odd;
    wire [$clog2(TIMEOUT+1)-1:0] c;
    
    // Register input comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_match_reg <= 0;
        end else begin
            current_match_reg <= current_match;
        end
    end
    
    // Generate initial propagate and generate signals
    assign p = counter | 3'b001;
    assign g = counter & 3'b001;
    
    // Han-Carlson pre-processing
    genvar i;
    generate
        for (i = 0; i < $clog2(TIMEOUT+1); i = i + 2) begin: even_bits
            assign p_even[i] = p[i];
            assign g_even[i] = g[i];
        end
        
        for (i = 1; i < $clog2(TIMEOUT+1); i = i + 2) begin: odd_bits
            assign p_odd[i] = p[i];
            assign g_odd[i] = g[i];
        end
    endgenerate
    
    // Han-Carlson tree
    assign c[0] = g_even[0];
    generate
        for (i = 2; i < $clog2(TIMEOUT+1); i = i + 2) begin: carry_even
            assign c[i] = g_even[i] | (p_even[i] & c[i-2]);
        end
    endgenerate
    
    generate
        for (i = 1; i < $clog2(TIMEOUT+1); i = i + 2) begin: carry_odd
            assign c[i] = g_odd[i] | (p_odd[i] & c[i-1]);
        end
    endgenerate
    
    // Final sum computation
    assign counter_next[0] = p[0];
    generate
        for (i = 1; i < $clog2(TIMEOUT+1); i = i + 1) begin: sum_bits
            assign counter_next[i] = p[i] ^ c[i-1];
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            match_valid <= 0;
            match_result <= 0;
        end else if (current_match_reg) begin
            counter <= 0;
            match_valid <= 1;
            match_result <= 1;
        end else if (counter < TIMEOUT) begin
            counter <= counter_next;
            match_valid <= 1;
            match_result <= 0;
        end else begin
            match_valid <= 0;
            match_result <= 0;
        end
    end
endmodule