//SystemVerilog
// Top-level module: Hierarchical variable step shifter
module shift_var_step #(parameter WIDTH=8) (
    input  wire                       clk,
    input  wire                       rst,
    input  wire [$clog2(WIDTH)-1:0]  step,
    input  wire [WIDTH-1:0]           din,
    output wire [WIDTH-1:0]           dout
);

    // Internal signal for combinatorial shift result
    wire [WIDTH-1:0] shifted_data;

    // Instantiation of shift operation submodule
    shift_var_step_shift #(.WIDTH(WIDTH)) u_shift (
        .din   (din),
        .step  (step),
        .dout  (shifted_data)
    );

    // Instantiation of output register submodule
    shift_var_step_reg #(.WIDTH(WIDTH)) u_reg (
        .clk   (clk),
        .rst   (rst),
        .din   (shifted_data),
        .dout  (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_var_step_shift
// Function: Performs variable left shift operation combinatorially
// -----------------------------------------------------------------------------
module shift_var_step_shift #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0]           din,
    input  wire [$clog2(WIDTH)-1:0]   step,
    output wire [WIDTH-1:0]           dout
);
    assign dout = din << step;
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_var_step_reg
// Function: Synchronously registers shift result with reset
// -----------------------------------------------------------------------------
module shift_var_step_reg #(parameter WIDTH=8) (
    input  wire                       clk,
    input  wire                       rst,
    input  wire [WIDTH-1:0]           din,
    output reg  [WIDTH-1:0]           dout
);
    always @(posedge clk or posedge rst) begin
        dout <= rst ? {WIDTH{1'b0}} : din;
    end
endmodule