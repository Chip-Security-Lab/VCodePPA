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
    
    // Buffered cam_entries for high fanout reduction
    reg [WIDTH-1:0] cam_entries_buf1 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_entries_buf2 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_entries_buf3 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_entries_buf4 [0:DEPTH/4-1];
    
    // Buffer cam_entries on clock edge to reduce fanout
    integer k;
    always @(posedge clk) begin
        k = 0;
        while (k < DEPTH/4) begin
            cam_entries_buf1[k] <= cam_entries[k];
            cam_entries_buf2[k] <= cam_entries[k+DEPTH/4];
            cam_entries_buf3[k] <= cam_entries[k+DEPTH/2];
            cam_entries_buf4[k] <= cam_entries[k+3*DEPTH/4];
            k = k + 1;
        end
    end
    
    // Debug port - read CAM entry on debug_clk
    always @(posedge debug_clk)
        debug_data <= cam_entries[debug_addr];
    
    // Regular CAM write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Reset all entries
            i = 0;
            while (i < DEPTH) begin
                cam_entries[i] <= {WIDTH{1'b0}};
                i = i + 1;
            end
        end else if (write_en) begin
            // Write operation
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Registered search data to reduce fanout
    reg [WIDTH-1:0] search_data_buf1, search_data_buf2;
    reg [WIDTH-1:0] search_data_buf3, search_data_buf4;
    
    always @(posedge clk) begin
        search_data_buf1 <= search_data;
        search_data_buf2 <= search_data;
        search_data_buf3 <= search_data;
        search_data_buf4 <= search_data;
    end
    
    // CAM search operation with reduced fanout
    genvar j;
    generate
        // Group 1
        for (j = 0; j < DEPTH/4; j = j + 1) begin : match_gen1
            assign match_lines[j] = (cam_entries_buf1[j] == search_data_buf1);
        end
        
        // Group 2
        for (j = DEPTH/4; j < DEPTH/2; j = j + 1) begin : match_gen2
            assign match_lines[j] = (cam_entries_buf2[j-DEPTH/4] == search_data_buf2);
        end
        
        // Group 3
        for (j = DEPTH/2; j < 3*DEPTH/4; j = j + 1) begin : match_gen3
            assign match_lines[j] = (cam_entries_buf3[j-DEPTH/2] == search_data_buf3);
        end
        
        // Group 4
        for (j = 3*DEPTH/4; j < DEPTH; j = j + 1) begin : match_gen4
            assign match_lines[j] = (cam_entries_buf4[j-3*DEPTH/4] == search_data_buf4);
        end
    endgenerate
endmodule