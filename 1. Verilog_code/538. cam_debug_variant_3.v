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
    output [DEPTH-1:0] match_lines // Match result
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // Buffered cam_entries for different consumers
    reg [WIDTH-1:0] cam_entries_debug;
    reg [WIDTH-1:0] cam_entries_match [0:3];  // 4 buffer registers for match logic
    
    // Debug port - read CAM entry on debug_clk with buffered access
    always @(posedge debug_clk) begin
        cam_entries_debug <= cam_entries[debug_addr];
        debug_data <= cam_entries_debug;
    end
    
    // Regular CAM write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Reset all entries
            for (i = 0; i < DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            // Write operation
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Buffer registers for search data to reduce fan-out
    reg [WIDTH-1:0] search_data_buf1, search_data_buf2;
    
    always @(posedge clk) begin
        search_data_buf1 <= search_data;
        search_data_buf2 <= search_data;
    end
    
    // Buffered cam_entries for match logic
    always @(posedge clk) begin
        for (i = 0; i < DEPTH; i=i+1) begin
            if (i < DEPTH/4)
                cam_entries_match[0][i] <= cam_entries[i];
            else if (i < DEPTH/2)
                cam_entries_match[1][i-DEPTH/4] <= cam_entries[i];
            else if (i < 3*DEPTH/4)
                cam_entries_match[2][i-DEPTH/2] <= cam_entries[i];
            else
                cam_entries_match[3][i-3*DEPTH/4] <= cam_entries[i];
        end
    end
    
    // CAM search operation with balanced load distribution
    wire [DEPTH-1:0] match_lines_internal;
    reg [DEPTH-1:0] match_lines_reg;
    
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : match_gen
            if (j < DEPTH/4)
                assign match_lines_internal[j] = (cam_entries_match[0][j] == search_data_buf1);
            else if (j < DEPTH/2)
                assign match_lines_internal[j] = (cam_entries_match[1][j-DEPTH/4] == search_data_buf1);
            else if (j < 3*DEPTH/4)
                assign match_lines_internal[j] = (cam_entries_match[2][j-DEPTH/2] == search_data_buf2);
            else
                assign match_lines_internal[j] = (cam_entries_match[3][j-3*DEPTH/4] == search_data_buf2);
        end
    endgenerate
    
    // Register match lines to improve timing
    always @(posedge clk) begin
        match_lines_reg <= match_lines_internal;
    end
    
    assign match_lines = match_lines_reg;
    
endmodule