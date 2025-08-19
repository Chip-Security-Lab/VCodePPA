//SystemVerilog
// Top-level module: Hierarchical 2-to-1 multiplexer
module ifelse_mux (
    input wire control,            // Control signal
    input wire [3:0] path_a,       // Data path A
    input wire [3:0] path_b,       // Data path B
    output wire [3:0] selected     // Output data path
);

    // Internal signal for mux output
    wire [3:0] mux_output;

    // Instantiate the 4-bit mux submodule
    mux_4bit u_mux_4bit (
        .sel(control),
        .in0(path_a),
        .in1(path_b),
        .out(mux_output)
    );

    // Assign mux output to selected output
    assign selected = mux_output;

endmodule

// -----------------------------------------------------------------------------
// Submodule: 4-bit 2-to-1 multiplexer
// Function: Selects between two 4-bit inputs based on the select signal
// -----------------------------------------------------------------------------
module mux_4bit (
    input wire sel,                // Select signal
    input wire [3:0] in0,          // Input 0
    input wire [3:0] in1,          // Input 1
    output wire [3:0] out          // Output
);

    reg [3:0] out_reg;
    integer i;

    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            if (sel) begin
                out_reg[i] = in1[i];
            end else begin
                out_reg[i] = in0[i];
            end
        end
    end

    assign out = out_reg;

endmodule