//SystemVerilog
// IEEE 1364-2005 Verilog standard
module ShiftLeft #(
    parameter WIDTH = 8
)(
    input wire clk,         // Clock input
    input wire rst_n,       // Active-low reset
    input wire en,          // Enable signal
    input wire serial_in,   // Serial input bit
    output reg [WIDTH-1:0] q // Parallel output register
);

    // Control signal encoding
    wire [1:0] ctrl;
    assign ctrl = {!rst_n, en};

    // Optimized shift register implementation using case statement
    always @(posedge clk) begin
        case (ctrl)
            2'b10: q <= {WIDTH{1'b0}};  // Reset state
            2'b01: q <= {q[WIDTH-2:0], serial_in};  // Shift operation
            default: q <= q;  // Hold state
        endcase
    end

endmodule