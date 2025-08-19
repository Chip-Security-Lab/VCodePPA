//SystemVerilog
// Top-level module: leading_zero
// Function: Hierarchical leading zero counter with functional submodules

module leading_zero #(parameter DW=8) (
    input  [DW-1:0] data,
    output [$clog2(DW+1)-1:0] count
);

    // Internal signals
    wire [$clog2(DW+1)-1:0] zero_count;
    wire [$clog2(DW+1)-1:0] first_one_pos;

    // Submodule: Find position of first '1' from MSB
    leading_zero_position #(.DW(DW)) u_leading_zero_position (
        .data_in(data),
        .first_one_pos(first_one_pos)
    );

    // Submodule: Convert position to leading zero count
    leading_zero_counter #(.DW(DW)) u_leading_zero_counter (
        .first_one_pos(first_one_pos),
        .zero_count(zero_count)
    );

    assign count = zero_count;

endmodule

// ---------------------------------------------------------------------
// Submodule: leading_zero_position
// Function: Finds the position of the first '1' bit from MSB
// ---------------------------------------------------------------------
module leading_zero_position #(parameter DW=8) (
    input  [DW-1:0] data_in,
    output reg [$clog2(DW+1)-1:0] first_one_pos
);
    integer idx;
    reg found;
    always @* begin
        found = 1'b0;
        first_one_pos = DW; // Default: all zeros
        for (idx = DW-1; idx >= 0; idx = idx - 1) begin
            if (!found && data_in[idx]) begin
                first_one_pos = idx;
                found = 1'b1;
            end
        end
    end
endmodule

// ---------------------------------------------------------------------
// Submodule: leading_zero_counter
// Function: Converts MSB-first '1' position to leading zero count
// ---------------------------------------------------------------------
module leading_zero_counter #(parameter DW=8) (
    input  [$clog2(DW+1)-1:0] first_one_pos,
    output reg [$clog2(DW+1)-1:0] zero_count
);
    always @* begin
        if (first_one_pos == DW)
            zero_count = DW;
        else
            zero_count = DW - 1 - first_one_pos;
    end
endmodule