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
    
    // Match operation using parallel prefix adders
    wire [WIDTH-1:0] exact_compare_result;
    wire [WIDTH-1:0] upper_compare_result;
    wire [WIDTH-1:0] lower_compare_result;
    wire [WIDTH-1:0] mask_compare_result;
    
    integer j;
    always @(*) begin
        for (j = 0; j < DEPTH; j = j + 1) begin
            case (match_mode)
                2'b00: // Exact match
                    match_lines[j] = (cam_entries[j] == search_data);
                
                2'b01: // Range match
                    match_lines[j] = parallel_prefix_compare(cam_entries[j], lower_bound, 1'b1) && 
                                     parallel_prefix_compare(upper_bound, cam_entries[j], 1'b1);
                
                2'b10: // Mask match (masked bits ignored)
                    match_lines[j] = ((cam_entries[j] & search_mask) == 
                                     (search_data & search_mask));
                
                default: // Default to exact match
                    match_lines[j] = (cam_entries[j] == search_data);
            endcase
        end
    end
    
    // Parallel prefix comparator function implementation
    function automatic parallel_prefix_compare;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        input equal_allowed;
        
        reg [3:0] a_sub, b_sub;
        reg [3:0] p, g;
        reg [3:0] p_stage1, g_stage1;
        reg [3:0] p_stage2, g_stage2;
        reg [4:0] carry;
        reg [3:0] sum;
        reg result;
        
        begin
            // For comparison, we use a 4-bit slice of the data
            a_sub = a[3:0];
            b_sub = b[3:0];
            
            // Generate propagate and generate signals
            p = a_sub ^ b_sub;
            g = a_sub & b_sub;
            
            // Parallel prefix stage 1
            p_stage1[0] = p[0];
            g_stage1[0] = g[0];
            
            p_stage1[1] = p[1] & p[0];
            g_stage1[1] = g[1] | (p[1] & g[0]);
            
            p_stage1[2] = p[2] & p[1] & p[0];
            g_stage1[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
            
            p_stage1[3] = p[3] & p[2] & p[1] & p[0];
            g_stage1[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
            
            // Calculate carry bits
            carry[0] = 1'b0; // No initial carry
            carry[1] = g[0];
            carry[2] = g_stage1[1];
            carry[3] = g_stage1[2];
            carry[4] = g_stage1[3]; // Carry out
            
            // Calculate sum
            sum = p ^ carry[3:0];
            
            // Determine comparison result
            if (a == b)
                result = equal_allowed;
            else if (carry[4] == 1'b0) // No carry out means a < b
                result = 1'b0;
            else
                result = 1'b1; // a > b
                
            parallel_prefix_compare = result;
        end
    endfunction
endmodule