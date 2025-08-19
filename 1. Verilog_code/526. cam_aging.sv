module cam_aging #(parameter WIDTH=8, DEPTH=16, AGING_BITS=4)(
    input clk,
    input [WIDTH-1:0] data_in,
    input search_en,
    output [DEPTH-1:0] match_hits
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [AGING_BITS-1:0] age_counters [0:DEPTH-1];
    
    integer i;
    always @(posedge clk) begin
        for (i=0; i<DEPTH; i=i+1) begin
            if (search_en && (data_in == entries[i]))
                age_counters[i] <= age_counters[i] + 1'b1;
            else if (age_counters[i] > {(AGING_BITS){1'b0}})
                age_counters[i] <= age_counters[i] - 1'b1;
        end
    end
    
    genvar j;
    generate
        for (j=0; j<DEPTH; j=j+1) begin: match_gen
            assign match_hits[j] = search_en && 
                                  (data_in == entries[j]) && 
                                  (age_counters[j] > {(AGING_BITS){1'b0}});
        end
    endgenerate
endmodule