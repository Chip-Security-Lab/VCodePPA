//SystemVerilog
module priority_encoder #(parameter WIDTH = 8, OUT_WIDTH = 3) (
    input wire [WIDTH-1:0] requests,
    output reg [OUT_WIDTH-1:0] grant_idx,
    output reg valid
);

    wire [WIDTH-1:0] one_hot_mask;
    wire [WIDTH-1:0] diff_result;

    // Simplified parallel prefix subtractor is inlined for bitwise optimization
    parallel_prefix_subtractor_8bit u_parallel_prefix_subtractor_8bit (
        .a({requests[WIDTH-2:0], 1'b0}),
        .b(requests),
        .diff(diff_result)
    );

    assign one_hot_mask = diff_result & requests;

    integer j;
    always @(*) begin
        grant_idx = {OUT_WIDTH{1'b0}};
        valid = 1'b0;
        for (j = WIDTH-1; j >= 0; j = j - 1) begin
            if (one_hot_mask[j]) begin
                grant_idx = j[OUT_WIDTH-1:0];
                valid = 1'b1;
            end
        end
    end

endmodule

module parallel_prefix_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff
);
    // Simplified Boolean expressions using Boolean algebra

    wire [7:0] borrow;
    wire [7:0] not_a;
    wire [7:0] not_b;
    wire [7:0] a_xor_b;

    assign not_a = ~a;
    assign not_b = ~b;
    assign a_xor_b = a ^ b;

    // Borrow chain simplification
    assign borrow[0] = not_a[0] & b[0];
    assign borrow[1] = (not_a[1] & b[1]) | (not_a[1] & borrow[0]) | (b[1] & borrow[0]);
    assign borrow[2] = (not_a[2] & b[2]) | (not_a[2] & borrow[1]) | (b[2] & borrow[1]);
    assign borrow[3] = (not_a[3] & b[3]) | (not_a[3] & borrow[2]) | (b[3] & borrow[2]);
    assign borrow[4] = (not_a[4] & b[4]) | (not_a[4] & borrow[3]) | (b[4] & borrow[3]);
    assign borrow[5] = (not_a[5] & b[5]) | (not_a[5] & borrow[4]) | (b[5] & borrow[4]);
    assign borrow[6] = (not_a[6] & b[6]) | (not_a[6] & borrow[5]) | (b[6] & borrow[5]);
    assign borrow[7] = (not_a[7] & b[7]) | (not_a[7] & borrow[6]) | (b[7] & borrow[6]);

    // Difference bits: a ^ b ^ borrow_in
    assign diff[0] = a_xor_b[0];
    assign diff[1] = a_xor_b[1] ^ borrow[0];
    assign diff[2] = a_xor_b[2] ^ borrow[1];
    assign diff[3] = a_xor_b[3] ^ borrow[2];
    assign diff[4] = a_xor_b[4] ^ borrow[3];
    assign diff[5] = a_xor_b[5] ^ borrow[4];
    assign diff[6] = a_xor_b[6] ^ borrow[5];
    assign diff[7] = a_xor_b[7] ^ borrow[6];

endmodule