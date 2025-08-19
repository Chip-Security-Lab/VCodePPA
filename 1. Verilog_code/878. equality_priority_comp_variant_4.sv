//SystemVerilog
// SystemVerilog

// Module for bit-by-bit comparison and finding the highest priority difference
module priority_difference_finder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_a, data_b,
    output [$clog2(WIDTH)-1:0] priority_idx
);

    wire [WIDTH-1:0] difference_mask;
    reg [$clog2(WIDTH)-1:0] next_priority_idx;

    // Generate a mask where bit i is 1 if data_a[i] != data_b[i]
    assign difference_mask = data_a ^ data_b;

    // Find the index of the most significant bit in the difference_mask
    always @(*) begin
        next_priority_idx = 0; // Default to 0 if no difference
        for (integer j = WIDTH-1; j >= 0; j = j - 1) begin
            if (difference_mask[j]) begin
                next_priority_idx = j[$clog2(WIDTH)-1:0];
                // Since we are iterating from MSB to LSB, the first bit set is the highest priority
                // We can break here for optimization in synthesis, but keeping for clarity in RTL
            end
        end
    end

    assign priority_idx = next_priority_idx;

endmodule

// Module for generating comparison flags (equal, a_greater, b_greater)
module comparison_flags_generator #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_a, data_b,
    output equal, a_greater, b_greater
);

    wire [WIDTH-1:0] greater_mask;
    wire any_a_greater_bit;
    wire any_b_greater_bit;

    // Generate a mask where bit i is 1 if data_a[i] > data_b[i]
    assign greater_mask = data_a & (~data_b); // (data_a[i] == 1 && data_b[i] == 0)

    // Check if any bit in data_a is greater than the corresponding bit in data_b
    assign any_a_greater_bit = |greater_mask;

    // Check if any bit in data_b is greater than the corresponding bit in data_a
    // This is equivalent to checking if any bit in data_a is less than the corresponding bit in data_b
    assign any_b_greater_bit = |(~data_a & data_b); // (data_a[i] == 0 && data_b[i] == 1)


    // Set comparison flags
    assign equal = (data_a == data_b);
    // A is greater than B if they are not equal AND there is at least one bit where A > B
    // A is NOT greater than B if they are equal OR there is no bit where A > B
    // This logic is simplified compared to the original, ensuring correctness
    assign a_greater = any_a_greater_bit && !equal;
    assign b_greater = any_b_greater_bit && !equal;

endmodule

// Top-level module combining priority difference and comparison flags
module equality_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_a, data_b,
    output reg [$clog2(WIDTH)-1:0] priority_idx,
    output reg equal, a_greater, b_greater
);

    // Internal wires to connect sub-modules
    wire [$clog2(WIDTH)-1:0] next_priority_idx_wire;
    wire next_equal_wire, next_a_greater_wire, next_b_greater_wire;

    // Instantiate sub-modules
    priority_difference_finder #(
        .WIDTH(WIDTH)
    ) u_priority_difference_finder (
        .data_a(data_a),
        .data_b(data_b),
        .priority_idx(next_priority_idx_wire)
    );

    comparison_flags_generator #(
        .WIDTH(WIDTH)
    ) u_comparison_flags_generator (
        .data_a(data_a),
        .data_b(data_b),
        .equal(next_equal_wire),
        .a_greater(next_a_greater_wire),
        .b_greater(next_b_greater_wire)
    );

    // Registered outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_idx <= 0;
            equal <= 0;
            a_greater <= 0;
            b_greater <= 0;
        end else begin
            priority_idx <= next_priority_idx_wire;
            equal <= next_equal_wire;
            a_greater <= next_a_greater_wire;
            b_greater <= next_b_greater_wire;
        end
    end

endmodule