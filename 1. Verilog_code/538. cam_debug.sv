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
        end else if (write_en) begin
            // Write operation
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // CAM search operation (combinational)
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : match_gen
            assign match_lines[j] = (cam_entries[j] == search_data);
        end
    endgenerate
endmodule