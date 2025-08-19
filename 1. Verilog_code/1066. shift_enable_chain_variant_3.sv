//SystemVerilog
// Top-level shift_enable_chain module with hierarchical structure

module shift_enable_chain #(parameter WIDTH=8) (
    input clk,
    input en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);

    // Internal signal declarations
    wire [WIDTH-1:0] din_reg_out;

    // Data Register Submodule: Latches din when enable is high
    data_register #(.WIDTH(WIDTH)) u_data_register (
        .clk    (clk),
        .en     (en),
        .din    (din),
        .dout   (din_reg_out)
    );

    // Shift Logic Submodule: Shifts the registered data left by 1 and inserts 0 at LSB
    shift_logic #(.WIDTH(WIDTH)) u_shift_logic (
        .clk    (clk),
        .en     (en),
        .din    (din_reg_out),
        .dout   (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Data Register Submodule
// Latches input data into output register when enable is high.
// -----------------------------------------------------------------------------
module data_register #(parameter WIDTH=8) (
    input clk,
    input en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    always @(posedge clk) begin
        if (en)
            dout <= din;
        else
            dout <= dout;
    end
endmodule

// -----------------------------------------------------------------------------
// Shift Logic Submodule
// Shifts input data left by 1 bit, inserts 0 at LSB, updates on enable.
// -----------------------------------------------------------------------------
module shift_logic #(parameter WIDTH=8) (
    input clk,
    input en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    always @(posedge clk) begin
        if (en)
            dout <= {din[WIDTH-2:0], 1'b0};
        else
            dout <= dout;
    end
endmodule