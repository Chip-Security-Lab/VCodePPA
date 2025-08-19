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
    output reg [DEPTH-1:0] match_lines // Match result
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // Search data pipeline registers with enable to reduce switching activity
    reg [WIDTH-1:0] search_data_buf;
    reg search_valid;
    
    // Partition CAM entries into smaller blocks for better performance
    reg [WIDTH-1:0] cam_block1 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_block2 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_block3 [0:DEPTH/4-1];
    reg [WIDTH-1:0] cam_block4 [0:DEPTH/4-1];
    
    // Pipeline registers for search data distribution to each block
    reg [WIDTH-1:0] search_data_block1;
    reg [WIDTH-1:0] search_data_block2;
    reg [WIDTH-1:0] search_data_block3;
    reg [WIDTH-1:0] search_data_block4;
    
    // Comparison intermediate results for each block
    reg [DEPTH/4-1:0][WIDTH-1:0] xor_result_block1;
    reg [DEPTH/4-1:0][WIDTH-1:0] xor_result_block2;
    reg [DEPTH/4-1:0][WIDTH-1:0] xor_result_block3;
    reg [DEPTH/4-1:0][WIDTH-1:0] xor_result_block4;
    
    // Comparison results for each block
    reg [DEPTH/4-1:0] match_block1;
    reg [DEPTH/4-1:0] match_block2;
    reg [DEPTH/4-1:0] match_block3;
    reg [DEPTH/4-1:0] match_block4;
    
    // Pipeline control signals
    reg search_valid_p1;
    reg search_valid_p2;
    
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
            search_valid <= 1'b0;
        end else begin
            // Write operation
            if (write_en)
                cam_entries[write_addr] <= write_data;
                
            // Register search data and generate valid signal
            search_data_buf <= search_data;
            search_valid <= 1'b1;
        end
    end
    
    // Pipeline stage for search valid signal
    always @(posedge clk) begin
        if (rst) begin
            search_valid_p1 <= 1'b0;
            search_valid_p2 <= 1'b0;
        end else begin
            search_valid_p1 <= search_valid;
            search_valid_p2 <= search_valid_p1;
        end
    end
    
    // Update block partitions only when necessary
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < DEPTH/4; k=k+1) begin
                cam_block1[k] <= 0;
                cam_block2[k] <= 0;
                cam_block3[k] <= 0;
                cam_block4[k] <= 0;
            end
        end else if (write_en) begin
            // Update only the specific block that contains the written address
            if (write_addr < DEPTH/4)
                cam_block1[write_addr] <= write_data;
            else if (write_addr < DEPTH/2)
                cam_block2[write_addr-DEPTH/4] <= write_data;
            else if (write_addr < 3*DEPTH/4)
                cam_block3[write_addr-DEPTH/2] <= write_data;
            else
                cam_block4[write_addr-3*DEPTH/4] <= write_data;
        end else begin
            // Periodic refresh to sync with main memory (could be optimized further)
            for (k = 0; k < DEPTH/4; k=k+1) begin
                cam_block1[k] <= cam_entries[k];
                cam_block2[k] <= cam_entries[k+DEPTH/4];
                cam_block3[k] <= cam_entries[k+DEPTH/2];
                cam_block4[k] <= cam_entries[k+3*DEPTH/4];
            end
        end
    end
    
    // Pipeline stage 1: Distribute search data to block-specific registers
    always @(posedge clk) begin
        if (rst) begin
            search_data_block1 <= 0;
            search_data_block2 <= 0;
            search_data_block3 <= 0;
            search_data_block4 <= 0;
        end else if (search_valid) begin
            search_data_block1 <= search_data_buf;
            search_data_block2 <= search_data_buf;
            search_data_block3 <= search_data_buf;
            search_data_block4 <= search_data_buf;
        end
    end
    
    // Pipeline stage 2: XOR computation (first part of comparison)
    integer j;
    always @(posedge clk) begin
        if (rst) begin
            for (j = 0; j < DEPTH/4; j=j+1) begin
                xor_result_block1[j] <= {WIDTH{1'b0}};
                xor_result_block2[j] <= {WIDTH{1'b0}};
                xor_result_block3[j] <= {WIDTH{1'b0}};
                xor_result_block4[j] <= {WIDTH{1'b0}};
            end
        end else if (search_valid_p1) begin
            for (j = 0; j < DEPTH/4; j=j+1) begin
                // XOR-based equality check (bits are 0 when equal)
                xor_result_block1[j] <= cam_block1[j] ^ search_data_block1;
                xor_result_block2[j] <= cam_block2[j] ^ search_data_block2;
                xor_result_block3[j] <= cam_block3[j] ^ search_data_block3;
                xor_result_block4[j] <= cam_block4[j] ^ search_data_block4;
            end
        end
    end
    
    // Pipeline stage 3: OR reduction and match determination
    always @(posedge clk) begin
        if (rst) begin
            match_block1 <= 0;
            match_block2 <= 0;
            match_block3 <= 0;
            match_block4 <= 0;
        end else if (search_valid_p2) begin
            for (j = 0; j < DEPTH/4; j=j+1) begin
                match_block1[j] <= ~|xor_result_block1[j];
                match_block2[j] <= ~|xor_result_block2[j];
                match_block3[j] <= ~|xor_result_block3[j];
                match_block4[j] <= ~|xor_result_block4[j];
            end
        end
    end
    
    // Final stage: Combine results
    always @(posedge clk) begin
        if (rst) begin
            match_lines <= 0;
        end else begin
            match_lines[0 +: DEPTH/4] <= match_block1;
            match_lines[DEPTH/4 +: DEPTH/4] <= match_block2;
            match_lines[DEPTH/2 +: DEPTH/4] <= match_block3;
            match_lines[3*DEPTH/4 +: DEPTH/4] <= match_block4;
        end
    end
endmodule