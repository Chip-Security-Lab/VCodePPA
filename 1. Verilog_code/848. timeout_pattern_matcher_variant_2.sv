//SystemVerilog
module timeout_pattern_matcher #(parameter W = 8, TIMEOUT = 7) (
    input clk, rst_n,
    input [W-1:0] data, pattern,
    output reg match_valid, match_result
);

    // Counter and match detection signals
    reg [$clog2(TIMEOUT+1)-1:0] counter;
    wire current_match = (data == pattern);
    
    // Manchester carry chain adder signals
    wire [$clog2(TIMEOUT+1)-1:0] counter_next;
    wire [$clog2(TIMEOUT+1)-1:0] counter_plus_one;
    wire [$clog2(TIMEOUT+1):0] carry;
    
    // Generate carry signals
    assign carry[0] = 1'b1;
    
    // Manchester carry chain logic
    genvar i;
    generate
        for (i = 0; i < $clog2(TIMEOUT+1); i = i + 1) begin: manchester_adder
            wire gen = counter[i] & carry[i];
            wire prop = counter[i];
            assign counter_plus_one[i] = prop ^ carry[i];
            assign carry[i+1] = gen | (prop & carry[i]);
        end
    endgenerate
    
    // Counter next value selection
    assign counter_next = current_match ? '0 : 
                         (counter < TIMEOUT) ? counter_plus_one : counter;

    // Counter update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (current_match) begin
            counter <= 0;
        end else if (counter < TIMEOUT) begin
            counter <= counter_next;
        end
    end

    // Match output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_valid <= 0;
            match_result <= 0;
        end else begin
            match_valid <= current_match || (counter < TIMEOUT);
            match_result <= current_match;
        end
    end

endmodule