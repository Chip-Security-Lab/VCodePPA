module cam_debug #(parameter WIDTH=16, DEPTH=64)(
    input debug_clk,
    input [6:0] debug_addr,
    output reg [WIDTH-1:0] debug_data,
    
    // Regular CAM interface
    input clk,                    // Main clock
    input rst,                    // Reset signal
    input write_en,               // Write enable
    input [6:0] write_addr,       // Write address
    input [WIDTH-1:0] write_data, // Data to write
    input [WIDTH-1:0] search_data,// Data to search for
    output reg [DEPTH-1:0] match_lines // Match result now registered
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    // Pipeline registers for search data
    reg [WIDTH-1:0] search_data_reg;
    // Intermediate comparison results
    wire [DEPTH-1:0] match_lines_comb;
    
    // Debug port - read CAM entry on debug_clk
    always @(posedge debug_clk)
        debug_data <= cam_entries[debug_addr];
    
    // Regular CAM write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Reset all entries
            for (i = 0; i < DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
            search_data_reg <= {WIDTH{1'b0}};
            match_lines <= {DEPTH{1'b0}};
        end else begin
            // Register search data to break timing path
            search_data_reg <= search_data;
            // Register match results to break timing path
            match_lines <= match_lines_comb;
            
            // Write operation
            if (write_en) begin
                cam_entries[write_addr] <= write_data;
            end
        end
    end
    
    // CAM search operation split into two stages:
    // 1. Combinational comparison using registered search data
    // 2. Results registered in the clock cycle
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : match_gen
            assign match_lines_comb[j] = (cam_entries[j] == search_data_reg);
        end
    endgenerate
endmodule