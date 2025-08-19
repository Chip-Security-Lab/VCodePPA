//SystemVerilog
// Top-level module: CaseMux
// Hierarchically instantiates Selector and OutputRegister submodules
module CaseMux #(
    parameter N = 4,
    parameter DW = 8
) (
    input  wire [$clog2(N)-1:0] sel,
    input  wire [N-1:0][DW-1:0] din,
    output wire [DW-1:0] dout
);

    wire [DW-1:0] selected_data;

    // Selector submodule: selects the data word based on 'sel'
    Selector #(
        .N(N),
        .DW(DW)
    ) u_selector (
        .sel(sel),
        .din(din),
        .dout(selected_data)
    );

    // OutputRegister submodule: holds the selected data (combinational)
    OutputRegister #(
        .DW(DW)
    ) u_output_reg (
        .din(selected_data),
        .dout(dout)
    );

endmodule

// Selector submodule: Selects one of the N data words based on the selection input
module Selector #(
    parameter N = 4,
    parameter DW = 8
) (
    input  wire [$clog2(N)-1:0] sel,
    input  wire [N-1:0][DW-1:0] din,
    output reg  [DW-1:0] dout
);
    // Combinational selection logic with conditional inversion subtractor
    reg [DW-1:0] subtrahend;
    reg [DW-1:0] minuend;
    reg subtract_enable;
    reg [DW-1:0] adder_input_b;
    reg adder_cin;
    wire [DW-1:0] adder_sum;

    integer i;
    always @* begin
        // Default assignments
        minuend = {DW{1'b0}};
        subtrahend = {DW{1'b0}};
        subtract_enable = 1'b0;
        // Select operation
        case (sel)
            0: begin
                // Pass-through din[0]
                dout = din[0];
            end
            1: begin
                // Pass-through din[1]
                dout = din[1];
            end
            2: begin
                // Subtraction using conditional inversion subtractor: din[2] - din[3]
                minuend = din[2];
                subtrahend = din[3];
                subtract_enable = 1'b1;
                dout = adder_sum;
            end
            3: begin
                // Addition: din[3] + din[0]
                dout = din[3] + din[0];
            end
            default: begin
                dout = {DW{1'b0}};
            end
        endcase
    end

    // Conditional inversion subtractor implementation
    // When subtract_enable is asserted, perform minuend + (~subtrahend) + 1
    always @* begin
        if (subtract_enable) begin
            adder_input_b = ~subtrahend;
            adder_cin = 1'b1;
        end else begin
            adder_input_b = subtrahend;
            adder_cin = 1'b0;
        end
    end

    assign adder_sum = minuend + adder_input_b + adder_cin;

endmodule

// OutputRegister submodule: Passes through the selected data (can be extended for pipelining/PPA)
// For now, this is a combinational pass-through; can be replaced with a register for timing closure
module OutputRegister #(
    parameter DW = 8
) (
    input  wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    // Direct assignment; can be changed to a register if pipelining is needed
    assign dout = din;
endmodule