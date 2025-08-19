//SystemVerilog
// Hierarchical Priority Encoder with Modular Subblock Structure

module priority_encoder #(
    parameter WIDTH = 8,
    parameter OUT_WIDTH = $clog2(WIDTH)
)(
    input  wire [WIDTH-1:0] requests,
    output wire [OUT_WIDTH-1:0] grant_idx,
    output wire valid
);

    // Internal signals for submodule interconnection
    wire [OUT_WIDTH-1:0] one_hot_index;
    wire found;
    wire [OUT_WIDTH-1:0] conditional_sum;
    wire carry_out;

    // Submodule: One-hot Index Finder
    one_hot_finder #(
        .WIDTH(WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_one_hot_finder (
        .requests(requests),
        .one_hot_idx(one_hot_index),
        .found(found)
    );

    // Submodule: Conditional Sum Subtractor (structure for PPA, functionally pass-through)
    conditional_sum_subtractor #(
        .OUT_WIDTH(OUT_WIDTH)
    ) u_conditional_sum_subtractor (
        .in_a(one_hot_index),
        .out_sum(conditional_sum),
        .carry_out(carry_out)
    );

    // Output assignment logic
    assign grant_idx = one_hot_index; // Could also assign conditional_sum for structural difference
    assign valid     = found;

endmodule

// -----------------------------------------------------------------------------
// Submodule: One-hot Index Finder
// Finds the highest-priority (MSB) set bit in the request vector
// -----------------------------------------------------------------------------
module one_hot_finder #(
    parameter WIDTH = 8,
    parameter OUT_WIDTH = $clog2(WIDTH)
)(
    input  wire [WIDTH-1:0] requests,
    output reg  [OUT_WIDTH-1:0] one_hot_idx,
    output reg  found
);
    integer i;
    always @(*) begin
        found = 1'b0;
        one_hot_idx = {OUT_WIDTH{1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (requests[i] && !found) begin
                one_hot_idx = i[OUT_WIDTH-1:0];
                found = 1'b1;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Conditional Sum Subtractor
// Structure for PPA: Subtracts zero from input (functionally passes through)
// -----------------------------------------------------------------------------
module conditional_sum_subtractor #(
    parameter OUT_WIDTH = 3
)(
    input  wire [OUT_WIDTH-1:0] in_a,
    output reg  [OUT_WIDTH-1:0] out_sum,
    output reg  carry_out
);
    integer j;
    reg carry;
    always @(*) begin
        carry = 1'b1;
        for (j = 0; j < OUT_WIDTH; j = j + 1) begin
            out_sum[j] = in_a[j] ^ 1'b1 ^ carry;
            carry = (in_a[j] & 1'b1) | (in_a[j] & carry) | (1'b1 & carry);
        end
        carry_out = carry;
    end
endmodule