module cam_aging #(parameter WIDTH=8, DEPTH=16, AGING_BITS=4)(
    input clk,
    input [WIDTH-1:0] data_in,
    input search_en,
    output [DEPTH-1:0] match_hits
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [AGING_BITS-1:0] age_counters [0:DEPTH-1];
    
    // Pre-compute match conditions to reduce critical path
    reg [DEPTH-1:0] entry_match;
    reg [DEPTH-1:0] counter_valid;
    
    integer i;
    
    // Split complex conditions into separate signals
    always @(*) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            entry_match[i] = (data_in == entries[i]);
            counter_valid[i] = (|age_counters[i]); // Optimized non-zero check
        end
    end
    
    // Counter update logic with balanced paths
    always @(posedge clk) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (search_en && entry_match[i]) begin
                // Increment counter on match
                if (age_counters[i] < {(AGING_BITS){1'b1}}) // Prevent overflow
                    age_counters[i] <= age_counters[i] + 1'b1;
            end else if (counter_valid[i]) begin
                // Decrement non-zero counter
                age_counters[i] <= age_counters[i] - 1'b1;
            end
        end
    end
    
    // Generate match hits using pre-computed signals
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin: match_gen
            assign match_hits[j] = search_en && entry_match[j] && counter_valid[j];
        end
    endgenerate
endmodule