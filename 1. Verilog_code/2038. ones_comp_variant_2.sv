//SystemVerilog
// Top-level module: Hierarchical ones' complement calculator with borrow lookahead subtractor
module ones_comp #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    // Internal signal for subtracted data
    wire [WIDTH-1:0] subtracted_data;

    // Instantiate the borrow lookahead subtractor submodule
    borrow_lookahead_subtractor #(.WIDTH(WIDTH)) u_borrow_lookahead_subtractor (
        .minuend    ({WIDTH{1'b1}}), // All ones for ones' complement
        .subtrahend (data_in),
        .difference (subtracted_data)
    );

    // Output assignment
    assign data_out = subtracted_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: borrow_lookahead_subtractor
// Purpose: Performs subtraction using borrow lookahead logic
// -----------------------------------------------------------------------------
module borrow_lookahead_subtractor #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] minuend,
    input  wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] difference
);

    wire [WIDTH-1:0] generate_borrow;
    wire [WIDTH-1:0] propagate_borrow;
    wire [WIDTH:0]   borrow_chain;

    assign borrow_chain[0] = 1'b0; // No initial borrow

    integer j;
    // Use while loops for the logic instead of for-generate
    reg [WIDTH-1:0] generate_borrow_reg;
    reg [WIDTH-1:0] propagate_borrow_reg;
    reg [WIDTH:0]   borrow_chain_reg;
    reg [WIDTH-1:0] difference_reg;

    always @(*) begin
        // Initialization
        borrow_chain_reg[0] = 1'b0;
        j = 0;
        // Generate and propagate borrow signals and borrow chain
        while (j < WIDTH) begin
            generate_borrow_reg[j]  = (~minuend[j]) & subtrahend[j];
            propagate_borrow_reg[j] = (~minuend[j]) | subtrahend[j];
            borrow_chain_reg[j+1]   = generate_borrow_reg[j] | (propagate_borrow_reg[j] & borrow_chain_reg[j]);
            difference_reg[j]       = minuend[j] ^ subtrahend[j] ^ borrow_chain_reg[j];
            j = j + 1;
        end
    end

    assign generate_borrow  = generate_borrow_reg;
    assign propagate_borrow = propagate_borrow_reg;
    assign borrow_chain     = borrow_chain_reg;
    assign difference       = difference_reg;

endmodule