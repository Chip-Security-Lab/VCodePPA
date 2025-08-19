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
    reg [7:0] block [0:N-1][0:N-1];
    reg [$clog2(N)-1:0] x_ptr, y_ptr;
    
    // Forward-retimed signals
    reg [7:0] pixel_in_reg;
    reg pixel_valid_reg;
    reg enable_reg;
    
    // Pipeline registers for control signals
    reg block_complete;
    reg [$clog2(N)-1:0] x_ptr_next, y_ptr_next;
    
    // First stage - register inputs
    always @(posedge clk) begin
        if (reset) begin
            pixel_in_reg <= 0;
            pixel_valid_reg <= 0;
            enable_reg <= 0;
        end else begin
            pixel_in_reg <= pixel_in;
            pixel_valid_reg <= pixel_valid;
            enable_reg <= enable;
        end
    end
    
    // Second stage - Control logic (flattened if-else structure)
    always @(posedge clk) begin
        if (reset) begin
            x_ptr <= 0;
            y_ptr <= 0;
            x_ptr_next <= 0;
            y_ptr_next <= 0;
            block_complete <= 0;
        end else begin
            // Default value
            block_complete <= 0;
            
            // Condition 1: enable_reg && pixel_valid_reg && x_ptr == N-1 && y_ptr == N-1
            if (enable_reg && pixel_valid_reg && x_ptr == N-1 && y_ptr == N-1) begin
                x_ptr_next <= 0;
                y_ptr_next <= 0;
                block_complete <= 1;
            end 
            // Condition 2: enable_reg && pixel_valid_reg && x_ptr == N-1 && y_ptr != N-1
            else if (enable_reg && pixel_valid_reg && x_ptr == N-1 && y_ptr != N-1) begin
                x_ptr_next <= 0;
                y_ptr_next <= y_ptr + 1;
            end 
            // Condition 3: enable_reg && pixel_valid_reg && x_ptr != N-1
            else if (enable_reg && pixel_valid_reg && x_ptr != N-1) begin
                x_ptr_next <= x_ptr + 1;
                y_ptr_next <= y_ptr;
            end
            
            // Update pointers when enabled and valid
            if (enable_reg && pixel_valid_reg) begin
                x_ptr <= x_ptr_next;
                y_ptr <= y_ptr_next;
            end
        end
    end
    
    // Third stage - Memory writes and output generation (flattened if-else structure)
    always @(posedge clk) begin
        if (reset) begin
            dct_valid <= 0;
            dct_out <= 0;
            coeff_idx <= 0;
        end else begin
            // Default value
            dct_valid <= 0;
            
            // Memory write condition
            if (enable_reg && pixel_valid_reg) begin
                // Store pixel in block (now using registered input)
                block[y_ptr][x_ptr] <= pixel_in_reg;
            end
                
            // Output generation condition
            if (enable_reg && pixel_valid_reg && block_complete) begin
                // Simplified DCT calculation
                dct_out <= $signed({3'b0, pixel_in_reg});
                coeff_idx <= 0;
                dct_valid <= 1;
            end
        end
    end
endmodule