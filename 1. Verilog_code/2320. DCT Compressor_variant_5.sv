//SystemVerilog
module dct_compressor #(
    parameter N = 4  // Block size
)(
    input                       clk,
    input                       reset,
    input                       enable,
    input      [7:0]            pixel_in,
    input                       pixel_valid,
    output reg [10:0]           dct_out,
    output reg                  dct_valid,
    output reg [$clog2(N*N)-1:0] coeff_idx
);
    // Block storage
    reg [7:0] block [0:N-1][0:N-1];
    reg [$clog2(N)-1:0] x_ptr, y_ptr;
    
    // Pipeline stage 1: Input collection and block completion detection
    reg block_complete_stage1;
    reg [7:0] pixel_stage1;
    reg [$clog2(N)-1:0] x_ptr_stage1, y_ptr_stage1;
    reg valid_stage1;
    
    // Pipeline registers for x_ptr and y_ptr logic
    reg [$clog2(N)-1:0] next_x_ptr, next_y_ptr;
    reg next_block_complete;
    
    // Pipeline stage 2: DCT preparation
    reg block_complete_stage2;
    reg [7:0] pixel_stage2;
    reg valid_stage2;
    reg [$clog2(N*N)-1:0] coeff_idx_stage2;
    
    // Additional pipeline registers for coeff_idx logic
    reg [$clog2(N*N)-1:0] next_coeff_idx;
    reg next_block_complete_stage2;
    
    // Pipeline stage 3: DCT calculation - split into two stages for timing
    reg [10:0] dct_result_stage3a; // Intermediate result
    reg valid_stage3a;
    reg [$clog2(N*N)-1:0] coeff_idx_stage3a;
    
    // Final DCT calculation stage
    reg [10:0] dct_result_stage3b;
    reg valid_stage3b;
    reg [$clog2(N*N)-1:0] coeff_idx_stage3b;
    
    // Stage 1 address logic - pre-calculate next pointers
    always @(*) begin
        if (x_ptr == N-1) begin
            next_x_ptr = 0;
            if (y_ptr == N-1) begin
                next_y_ptr = 0;
                next_block_complete = 1;
            end else begin
                next_y_ptr = y_ptr + 1;
                next_block_complete = 0;
            end
        end else begin
            next_x_ptr = x_ptr + 1;
            next_y_ptr = y_ptr;
            next_block_complete = 0;
        end
    end
    
    // Stage 1: Input collection and control
    always @(posedge clk) begin
        if (reset) begin
            x_ptr <= 0;
            y_ptr <= 0;
            block_complete_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable && pixel_valid) begin
            // Store pixel in block
            block[y_ptr][x_ptr] <= pixel_in;
            
            // Pass data to next stage
            pixel_stage1 <= pixel_in;
            x_ptr_stage1 <= x_ptr;
            y_ptr_stage1 <= y_ptr;
            valid_stage1 <= 1;
            
            // Update pointers and detect block completion using pre-calculated values
            x_ptr <= next_x_ptr;
            y_ptr <= next_y_ptr;
            block_complete_stage1 <= next_block_complete;
        end else begin
            valid_stage1 <= 0;
            block_complete_stage1 <= 0;
        end
    end
    
    // Pre-calculate next coefficient index
    always @(*) begin
        if (block_complete_stage1 && valid_stage1) begin
            next_coeff_idx = 0;
            next_block_complete_stage2 = 1;
        end else if (valid_stage2 && block_complete_stage2) begin
            if (coeff_idx_stage2 == N*N-1) begin
                next_coeff_idx = coeff_idx_stage2;
                next_block_complete_stage2 = 0;
            end else begin
                next_coeff_idx = coeff_idx_stage2 + 1;
                next_block_complete_stage2 = 1;
            end
        end else begin
            next_coeff_idx = coeff_idx_stage2;
            next_block_complete_stage2 = block_complete_stage2;
        end
    end
    
    // Stage 2: DCT preparation
    always @(posedge clk) begin
        if (reset) begin
            valid_stage2 <= 0;
            block_complete_stage2 <= 0;
            coeff_idx_stage2 <= 0;
        end else if (enable) begin
            valid_stage2 <= valid_stage1;
            pixel_stage2 <= pixel_stage1;
            
            // Use pre-calculated values
            if (block_complete_stage1 && valid_stage1) begin
                coeff_idx_stage2 <= 0;
                block_complete_stage2 <= 1;
            end else if (valid_stage2 && block_complete_stage2) begin
                coeff_idx_stage2 <= next_coeff_idx;
                block_complete_stage2 <= next_block_complete_stage2;
            end else begin
                block_complete_stage2 <= block_complete_stage2;
            end
        end
    end
    
    // Stage 3a: First part of DCT calculation
    always @(posedge clk) begin
        if (reset) begin
            valid_stage3a <= 0;
            dct_result_stage3a <= 0;
            coeff_idx_stage3a <= 0;
        end else if (enable) begin
            valid_stage3a <= valid_stage2 && block_complete_stage2;
            coeff_idx_stage3a <= coeff_idx_stage2;
            
            // First part of DCT calculation (split for timing)
            if (valid_stage2 && block_complete_stage2) begin
                // In a real implementation, this would be part of the actual DCT math
                dct_result_stage3a <= {3'b000, pixel_stage2};
            end
        end
    end
    
    // Stage 3b: Second part of DCT calculation
    always @(posedge clk) begin
        if (reset) begin
            valid_stage3b <= 0;
            dct_result_stage3b <= 0;
            coeff_idx_stage3b <= 0;
        end else if (enable) begin
            valid_stage3b <= valid_stage3a;
            coeff_idx_stage3b <= coeff_idx_stage3a;
            
            // Second part of DCT calculation
            if (valid_stage3a) begin
                // In a real implementation, this would be the final part of the DCT math
                // Currently just a placeholder that makes the sign extension explicit
                dct_result_stage3b <= $signed(dct_result_stage3a);
            end
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (reset) begin
            dct_valid <= 0;
            dct_out <= 0;
            coeff_idx <= 0;
        end else if (enable) begin
            dct_valid <= valid_stage3b;
            dct_out <= dct_result_stage3b;
            coeff_idx <= coeff_idx_stage3b;
        end
    end
endmodule