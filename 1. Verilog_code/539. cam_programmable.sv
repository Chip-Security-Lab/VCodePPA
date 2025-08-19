module cam_programmable #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input rst,
    input [1:0] match_mode, // 00: exact, 01: range, 10: mask
    input [WIDTH-1:0] search_data,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    input [WIDTH-1:0] search_mask,
    
    // Write interface
    input write_en,
    input [3:0] write_addr,
    input [WIDTH-1:0] write_data,
    
    // Output match lines
    output reg [DEPTH-1:0] match_lines
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // Write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Match operation
    integer j;
    always @(*) begin
        for (j = 0; j < DEPTH; j = j + 1) begin
            case (match_mode)
                2'b00: // Exact match
                    match_lines[j] = (cam_entries[j] == search_data);
                
                2'b01: // Range match
                    match_lines[j] = (cam_entries[j] >= lower_bound) && 
                                     (cam_entries[j] <= upper_bound);
                
                2'b10: // Mask match (masked bits ignored)
                    match_lines[j] = ((cam_entries[j] & search_mask) == 
                                     (search_data & search_mask));
                
                default: // Default to exact match
                    match_lines[j] = (cam_entries[j] == search_data);
            endcase
        end
    end
endmodule