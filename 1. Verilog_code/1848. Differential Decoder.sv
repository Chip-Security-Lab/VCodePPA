module differential_decoder (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in,
    output reg        decoded_out,
    output wire       parity_error
);
    reg prev_diff_in;
    reg parity_bit;
    
    // Decode differential data
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            prev_diff_in <= 1'b0;
            decoded_out <= 1'b0;
            parity_bit <= 1'b0;
        end else begin
            prev_diff_in <= diff_in;
            decoded_out <= diff_in ^ prev_diff_in;
            parity_bit <= parity_bit ^ decoded_out;
        end
    end
    
    // Simple error detection (toggles every 8 bits)
    reg [2:0] bit_counter;
    reg expected_parity;
    
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            bit_counter <= 3'b000;
            expected_parity <= 1'b0;
        end else begin
            bit_counter <= bit_counter + 1'b1;
            
            if (bit_counter == 3'b111)
                expected_parity <= ~expected_parity;
        end
    end
    
    assign parity_error = (bit_counter == 3'b000) ? (parity_bit != expected_parity) : 1'b0;
endmodule