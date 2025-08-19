module cam_debug #(
    parameter WIDTH = 16,
    parameter DEPTH = 64
)(
    // Debug interface
    input                  debug_clk,
    input      [6:0]       debug_addr,
    output reg [WIDTH-1:0] debug_data,
    
    // Regular CAM interface
    input                  clk,          // Main clock
    input                  rst,          // Reset signal
    input                  write_en,     // Write enable
    input      [6:0]       write_addr,   // Write address
    input      [WIDTH-1:0] write_data,   // Data to write
    input      [WIDTH-1:0] search_data,  // Data to search for
    output     [DEPTH-1:0] match_lines   // Match result
);
    // CAM storage - main memory array
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    //========== Debug Address Generation Pipeline ==========//
    // Improved Fast Adder with Pipelining for address computation
    
    // Stage 1: Generate propagate and generate signals
    reg [6:0] debug_addr_r;
    reg [6:0] p_stage1, g_stage1;
    
    always @(posedge debug_clk) begin
        debug_addr_r <= debug_addr;
        p_stage1 <= debug_addr ^ 7'b0000001;  // Propagate = A XOR B
        g_stage1 <= debug_addr & 7'b0000001;  // Generate = A AND B
    end
    
    // Stage 2: Calculate carries with improved structure
    reg [6:0] c_stage2;
    reg [6:0] p_stage2, g_stage2;
    
    always @(posedge debug_clk) begin
        p_stage2 <= p_stage1;
        g_stage2 <= g_stage1;
        
        // Optimized carry calculation with reduced logic depth
        c_stage2[0] <= g_stage1[0];
        c_stage2[1] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
        c_stage2[2] <= g_stage1[2] | (p_stage1[2] & (g_stage1[1] | (p_stage1[1] & g_stage1[0])));
        c_stage2[3] <= g_stage1[3] | (p_stage1[3] & c_stage2[2]);
        c_stage2[4] <= g_stage1[4] | (p_stage1[4] & c_stage2[3]);
        c_stage2[5] <= g_stage1[5] | (p_stage1[5] & c_stage2[4]);
        c_stage2[6] <= g_stage1[6] | (p_stage1[6] & c_stage2[5]);
    end
    
    // Stage 3: Compute final address and read from memory
    reg [6:0] addr_next;
    
    always @(posedge debug_clk) begin
        // Final sum computation
        addr_next[0] <= p_stage2[0];
        addr_next[1] <= p_stage2[1] ^ c_stage2[0];
        addr_next[2] <= p_stage2[2] ^ c_stage2[1];
        addr_next[3] <= p_stage2[3] ^ c_stage2[2];
        addr_next[4] <= p_stage2[4] ^ c_stage2[3];
        addr_next[5] <= p_stage2[5] ^ c_stage2[4];
        addr_next[6] <= p_stage2[6] ^ c_stage2[5];
        
        // Read data from CAM memory using the current address
        debug_data <= cam_entries[debug_addr_r];
    end
    
    //========== CAM Write Datapath ==========//
    // Regular CAM write operation with improved structure
    
    // Stage 1: Register write control signals
    reg              write_en_r;
    reg [6:0]        write_addr_r;
    reg [WIDTH-1:0]  write_data_r;
    
    always @(posedge clk) begin
        write_en_r   <= write_en;
        write_addr_r <= write_addr;
        write_data_r <= write_data;
    end
    
    // Stage 2: Memory write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Reset all entries
            for (i = 0; i < DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en_r) begin
            // Write operation with registered signals
            cam_entries[write_addr_r] <= write_data_r;
        end
    end
    
    //========== CAM Search Datapath ==========//
    // CAM search operation with pipelined structure
    
    // Stage 1: Register search data
    reg [WIDTH-1:0] search_data_r;
    
    always @(posedge clk) begin
        search_data_r <= search_data;
    end
    
    // Stage 2: Perform comparison in segments for better timing
    reg [DEPTH-1:0] match_segments [0:1]; // Split comparisons into segments
    
    genvar j;
    generate
        for (j = 0; j < DEPTH/2; j = j + 1) begin : match_lower_half
            // Lower half comparison logic
            always @(posedge clk) begin
                match_segments[0][j] <= (cam_entries[j] == search_data_r);
            end
        end
        
        for (j = DEPTH/2; j < DEPTH; j = j + 1) begin : match_upper_half
            // Upper half comparison logic
            always @(posedge clk) begin
                match_segments[1][j-DEPTH/2] <= (cam_entries[j] == search_data_r);
            end
        end
    endgenerate
    
    // Stage 3: Combine match results
    reg [DEPTH-1:0] match_lines_r;
    
    genvar k;
    generate
        for (k = 0; k < DEPTH/2; k = k + 1) begin : combine_matches_lower
            assign match_lines[k] = match_segments[0][k];
        end
        
        for (k = DEPTH/2; k < DEPTH; k = k + 1) begin : combine_matches_upper
            assign match_lines[k] = match_segments[1][k-DEPTH/2];
        end
    endgenerate
    
endmodule