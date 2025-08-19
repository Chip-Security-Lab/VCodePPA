//SystemVerilog
module SignedMultiplier(
    input  clk, rst_n,
    input  signed [7:0] a, b,
    output signed [15:0] result
);
    // Pipeline stage 1: Sign extraction and absolute value calculation
    reg [7:0] abs_a_r, abs_b_r;
    reg sign_a_r, sign_b_r;
    
    // Pipeline stage 2: Unsigned multiplication
    reg [15:0] unsigned_result_r;
    reg sign_a_r2, sign_b_r2;
    
    // Pipeline stage 3: Sign correction and result assembly
    reg [15:0] unsigned_result_r2;
    reg result_sign_r;
    
    // Stage 1: Sign extraction and absolute value calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_a_r <= 8'b0;
            abs_b_r <= 8'b0;
            sign_a_r <= 1'b0;
            sign_b_r <= 1'b0;
        end else begin
            // Optimized sign extraction and absolute value calculation
            sign_a_r <= a[7];  // MSB is sign bit
            sign_b_r <= b[7];
            abs_a_r <= a[7] ? -a : a;
            abs_b_r <= b[7] ? -b : b;
        end
    end
    
    // Stage 2: Unsigned multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_result_r <= 16'b0;
            sign_a_r2 <= 1'b0;
            sign_b_r2 <= 1'b0;
        end else begin
            unsigned_result_r <= abs_a_r * abs_b_r;
            sign_a_r2 <= sign_a_r;
            sign_b_r2 <= sign_b_r;
        end
    end
    
    // Stage 3: Sign correction and result assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_result_r2 <= 16'b0;
            result_sign_r <= 1'b0;
        end else begin
            unsigned_result_r2 <= unsigned_result_r;
            result_sign_r <= sign_a_r2 ^ sign_b_r2;
        end
    end
    
    // Final result assignment - optimized for better timing
    assign result = result_sign_r ? -unsigned_result_r2 : unsigned_result_r2;
endmodule