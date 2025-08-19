//SystemVerilog
// Top-level module: shift_max_detect
// Function: Detects the minimum index (shift amount) of set bit in input din.
// Structure: Hierarchically organized into data register and max shift detector submodules.

module shift_max_detect #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output [$clog2(W)-1:0] max_shift
);

    wire [W-1:0] data_reg_out;
    wire [$clog2(W)-1:0] max_shift_wire;

    data_register #(.W(W)) u_data_register (
        .clk(clk),
        .din(din),
        .dout(data_reg_out)
    );

    max_shift_detector #(.W(W)) u_max_shift_detector (
        .clk(clk),
        .data_in(data_reg_out),
        .max_shift_out(max_shift_wire)
    );

    assign max_shift = max_shift_wire;

endmodule

// -----------------------------------------------------------------------------
// Submodule: data_register
// Function: Registers input data at each clock edge
// -----------------------------------------------------------------------------
module data_register #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

    always @(posedge clk) begin
        dout <= din;
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: max_shift_detector
// Function: Finds the lowest index with '1' in input data_in
// Optimized with multiple small always blocks for improved modularity and timing
// -----------------------------------------------------------------------------
module max_shift_detector #(parameter W=8) (
    input clk,
    input [W-1:0] data_in,
    output reg [$clog2(W)-1:0] max_shift_out
);

    reg [$clog2(W)-1:0] min_index_comb;
    reg [$clog2(W)-1:0] min_index_reg;
    integer idx;

    // Combinational always block for minimum index calculation
    always @(*) begin
        min_index_comb = {($clog2(W)){1'b1}}; // Default to maximum possible value
        for (idx = 0; idx < W; idx = idx + 1) begin
            if (data_in[idx] == 1'b1 && idx < min_index_comb) begin
                min_index_comb = idx[$clog2(W)-1:0];
            end
        end
        if (min_index_comb == {($clog2(W)){1'b1}}) begin
            min_index_comb = W-1;
        end
    end

    // Sequential always block to register min_index_comb
    always @(posedge clk) begin
        min_index_reg <= min_index_comb;
    end

    // Output assignment in a separate always block for clarity
    always @(posedge clk) begin
        max_shift_out <= min_index_reg;
    end

endmodule