//SystemVerilog
module dct_compressor #(
    parameter N = 4  // Block size
)(
    input                  clk,
    input                  reset,
    input                  enable,
    input      [7:0]       pixel_in,
    input                  pixel_valid,
    output     [10:0]      dct_out,
    output                 dct_valid,
    output     [$clog2(N*N)-1:0] coeff_idx
);
    // IEEE 1364-2005 Verilog standard
    
    // Storage for input pixels
    reg [7:0] block [0:N-1][0:N-1];
    // Block position tracking
    reg [$clog2(N)-1:0] x_ptr, y_ptr;
    // Pre-calculation signals for improved timing
    reg block_complete;
    reg [10:0] dct_data;
    reg [$clog2(N*N)-1:0] coeff_counter;
    
    // Pipeline registers (moved from output)
    reg dct_valid_r;
    reg [10:0] dct_out_r;
    reg [$clog2(N*N)-1:0] coeff_idx_r;
    
    // Connect output through retimed registers
    assign dct_valid = dct_valid_r;
    assign dct_out = dct_out_r;
    assign coeff_idx = coeff_idx_r;
    
    // Input processing and block management
    always @(posedge clk) begin
        if (reset) begin
            x_ptr <= 0;
            y_ptr <= 0;
            block_complete <= 0;
            coeff_counter <= 0;
        end else if (enable && pixel_valid) begin
            // Store pixel in block
            block[y_ptr][x_ptr] <= pixel_in;
            
            // Update pointers
            if (x_ptr == N-1) begin
                x_ptr <= 0;
                if (y_ptr == N-1) begin
                    y_ptr <= 0;
                    // Block complete - set flag for DCT calculation
                    block_complete <= 1;
                    // Pre-calculate DCT data (simplified as per original)
                    dct_data <= $signed({3'b0, pixel_in});
                    coeff_counter <= 0;
                end else begin
                    y_ptr <= y_ptr + 1;
                    block_complete <= 0;
                end
            end else begin
                x_ptr <= x_ptr + 1;
                block_complete <= 0;
            end
        end else begin
            block_complete <= 0;
        end
    end
    
    // Output stage with retimed registers
    always @(posedge clk) begin
        if (reset) begin
            dct_valid_r <= 0;
            dct_out_r <= 0;
            coeff_idx_r <= 0;
        end else begin
            // Process output based on completion flag
            dct_valid_r <= block_complete;
            
            // Propagate data when block is complete
            if (block_complete) begin
                dct_out_r <= dct_data;
                coeff_idx_r <= coeff_counter;
            end else begin
                dct_valid_r <= 0;
            end
        end
    end
endmodule