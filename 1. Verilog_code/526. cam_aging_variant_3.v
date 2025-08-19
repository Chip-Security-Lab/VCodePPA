module cam_aging #(parameter WIDTH=8, DEPTH=16, AGING_BITS=4)(
    input clk,
    input [WIDTH-1:0] data_in,
    input search_en,
    output [DEPTH-1:0] match_hits
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [AGING_BITS-1:0] age_counters [0:DEPTH-1];

    // Always block for updating age counters
    always @(posedge clk) begin
        update_age_counters();
    end

    // Function to update age counters based on search enable and data input
    task update_age_counters();
        integer i;
        for (i=0; i<DEPTH; i=i+1) begin
            case ({search_en, data_in == entries[i], age_counters[i] > {(AGING_BITS){1'b0}}})
                3'b100: age_counters[i] <= age_counters[i] + 1'b1; // Increment age counter
                3'b011: age_counters[i] <= age_counters[i] - 1'b1; // Decrement age counter
                default: age_counters[i] <= age_counters[i]; // No change
            endcase
        end
    endtask

    // Generate block for match hits
    genvar j;
    generate
        for (j=0; j<DEPTH; j=j+1) begin: match_gen
            assign match_hits[j] = search_en && 
                                    (data_in == entries[j]) && 
                                    (age_counters[j] > {(AGING_BITS){1'b0}});
        end
    endgenerate
endmodule