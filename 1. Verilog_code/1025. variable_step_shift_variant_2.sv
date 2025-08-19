//SystemVerilog
// Top-level module: variable_step_shift
// Function: Variable step shifter with parameterizable width and step control
// Hierarchical design: Output register moved after shift logic (forward retiming)

module variable_step_shift #(parameter W=8) (
    input                   clk,
    input       [1:0]       step,
    input       [W-1:0]     din,
    output      [W-1:0]     dout
);

    wire [1:0]    step_reg;
    wire [W-1:0]  din_reg;

    // Input register logic moved after combination logic (retimed)
    // No register at input, registered after shift logic

    // Shift logic submodule instance (combinational)
    wire [W-1:0] shifted_data;
    shift_logic #(.W(W)) u_shift_logic (
        .shift_sel   (step),
        .data_in     (din),
        .data_shifted(shifted_data)
    );

    // Output register now captures shift result (forward retiming)
    reg [W-1:0] dout_reg;
    always @(posedge clk) begin
        dout_reg <= shifted_data;
    end
    assign dout = dout_reg;

endmodule

// ---------------------------------------------------------------------------
// Submodule: shift_logic
// Purpose:   Combinational logic to select and perform variable left shift
// ---------------------------------------------------------------------------
module shift_logic #(parameter W=8) (
    input      [1:0]      shift_sel,
    input      [W-1:0]    data_in,
    output reg [W-1:0]    data_shifted
);
    always @(*) begin
        case(shift_sel)
            2'd0: data_shifted = data_in;
            2'd1: data_shifted = {data_in[W-2:0], 1'b0};
            2'd2: data_shifted = {data_in[W-3:0], 2'b00};
            2'd3: data_shifted = {data_in[W-5:0], 4'b0000};
            default: data_shifted = data_in;
        endcase
    end
endmodule