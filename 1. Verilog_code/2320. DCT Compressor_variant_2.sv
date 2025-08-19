//SystemVerilog
module dct_compressor #(
    parameter N = 4  // Block size
)(
    input                  clk,
    input                  reset,
    input                  enable,
    input      [7:0]       pixel_in,
    input                  pixel_valid,
    output reg [10:0]      dct_out,
    output reg             dct_valid,
    output reg [$clog2(N*N)-1:0] coeff_idx
);
    // Stage 1: Input registration and block storage
    reg [7:0] pixel_in_stage1;
    reg enable_stage1, pixel_valid_stage1;
    reg [$clog2(N)-1:0] x_ptr_stage1, y_ptr_stage1;
    reg [$clog2(N)-1:0] next_x_ptr_stage1, next_y_ptr_stage1;
    reg block_complete_stage1;
    reg [7:0] block [0:N-1][0:N-1];
    
    // Stage 2: DCT computation preparation
    reg [7:0] pixel_for_dct_stage2;
    reg block_complete_stage2;
    reg [$clog2(N)-1:0] x_ptr_stage2, y_ptr_stage2;
    
    // Stage 3: DCT computation and output
    reg [10:0] dct_result_stage3;
    reg dct_valid_stage3;
    reg [$clog2(N*N)-1:0] coeff_idx_stage3;
    
    // Pre-compute next pointer values to improve timing
    always @(*) begin
        if (x_ptr_stage1 == N-1) begin
            next_x_ptr_stage1 = 0;
            if (y_ptr_stage1 == N-1)
                next_y_ptr_stage1 = 0;
            else
                next_y_ptr_stage1 = y_ptr_stage1 + 1;
            block_complete_stage1 = (y_ptr_stage1 == N-1);
        end else begin
            next_x_ptr_stage1 = x_ptr_stage1 + 1;
            next_y_ptr_stage1 = y_ptr_stage1;
            block_complete_stage1 = 0;
        end
    end
    
    // Pipeline Stage 1: Input registration and block storage
    always @(posedge clk) begin
        if (reset) begin
            pixel_in_stage1 <= 0;
            enable_stage1 <= 0;
            pixel_valid_stage1 <= 0;
            x_ptr_stage1 <= 0;
            y_ptr_stage1 <= 0;
        end else begin
            pixel_in_stage1 <= pixel_in;
            enable_stage1 <= enable;
            pixel_valid_stage1 <= pixel_valid;
            
            if (enable_stage1 && pixel_valid_stage1) begin
                // Store pixel in block
                block[y_ptr_stage1][x_ptr_stage1] <= pixel_in_stage1;
                
                // Update pointers
                x_ptr_stage1 <= next_x_ptr_stage1;
                y_ptr_stage1 <= next_y_ptr_stage1;
            end
        end
    end
    
    // Pipeline Stage 2: DCT computation preparation
    always @(posedge clk) begin
        if (reset) begin
            pixel_for_dct_stage2 <= 0;
            block_complete_stage2 <= 0;
            x_ptr_stage2 <= 0;
            y_ptr_stage2 <= 0;
        end else begin
            pixel_for_dct_stage2 <= pixel_in_stage1;
            block_complete_stage2 <= block_complete_stage1 && enable_stage1 && pixel_valid_stage1;
            x_ptr_stage2 <= x_ptr_stage1;
            y_ptr_stage2 <= y_ptr_stage1;
        end
    end
    
    // Pipeline Stage 3: DCT computation and output
    always @(posedge clk) begin
        if (reset) begin
            dct_result_stage3 <= 0;
            dct_valid_stage3 <= 0;
            coeff_idx_stage3 <= 0;
        end else begin
            // In a real implementation, this would be where the actual DCT math happens
            // This is simplified - just using the registered input as coefficient
            if (block_complete_stage2) begin
                dct_result_stage3 <= $signed({3'b0, pixel_for_dct_stage2});
                dct_valid_stage3 <= 1;
                coeff_idx_stage3 <= 0;
            end else begin
                dct_valid_stage3 <= 0;
            end
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (reset) begin
            dct_out <= 0;
            dct_valid <= 0;
            coeff_idx <= 0;
        end else begin
            dct_out <= dct_result_stage3;
            dct_valid <= dct_valid_stage3;
            coeff_idx <= coeff_idx_stage3;
        end
    end
endmodule