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
    
    always @(posedge clk) begin
        if (reset) begin
            x_ptr <= 0;
            y_ptr <= 0;
            dct_valid <= 0;
        end else if (enable && pixel_valid) begin
            // Store pixel in block
            block[y_ptr][x_ptr] <= pixel_in;
            
            // Update pointers
            if (x_ptr == N-1) begin
                x_ptr <= 0;
                if (y_ptr == N-1) begin
                    y_ptr <= 0;
                    // Block complete - DCT would be calculated here
                    // This is simplified - just use input as coefficient
                    dct_out <= $signed({3'b0, pixel_in});
                    coeff_idx <= 0;
                    dct_valid <= 1;
                end else begin
                    y_ptr <= y_ptr + 1;
                end
            end else begin
                x_ptr <= x_ptr + 1;
            end
        end else begin
            dct_valid <= 0;
        end
    end
endmodule