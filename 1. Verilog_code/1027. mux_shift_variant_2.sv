//SystemVerilog
module mux_shift #(parameter W=8) (
    input  wire [W-1:0] din,
    input  wire [1:0]   sel,
    output reg  [W-1:0] dout
);
    reg [W-1:0] mux_out0, mux_out1, mux_out2, mux_out3;

    // 2-bit Parallel Prefix Subtractor Module Declaration
    function [1:0] parallel_prefix_sub_2bit;
        input [1:0] a;
        input [1:0] b;
        input       borrow_in;
        reg [1:0] difference;
        reg        borrow0, borrow1;
        reg        generate0, generate1, propagate0, propagate1;
        reg        borrow_out0, borrow_out1;
        begin
            // Generate and Propagate signals
            generate0  = (~a[0]) & b[0];
            propagate0 = a[0] ^ b[0];
            borrow0    = generate0 | (propagate0 & borrow_in);

            generate1  = (~a[1]) & b[1];
            propagate1 = a[1] ^ b[1];
            borrow1    = generate1 | (propagate1 & borrow0);

            difference[0] = a[0] ^ b[0] ^ borrow_in;
            difference[1] = a[1] ^ b[1] ^ borrow0;

            parallel_prefix_sub_2bit = difference;
        end
    endfunction

    always @* begin
        mux_out0 = din;
        // Subtraction by 1 using 2-bit parallel prefix subtractor for lower 2 bits
        mux_out1 = {din[W-1:2], parallel_prefix_sub_2bit(din[1:0], 2'b01, 1'b0)};
        // Subtraction by 2 using 2-bit parallel prefix subtractor for lower 2 bits
        mux_out2 = {din[W-1:2], parallel_prefix_sub_2bit(din[1:0], 2'b10, 1'b0)};
        // Subtraction by 4 using 2-bit parallel prefix subtractor for lower 2 bits
        mux_out3 = {din[W-1:2], parallel_prefix_sub_2bit(din[1:0], 2'b00, 1'b0)};
        // For subtraction by 4, since 2'b00, just pass through din[1:0]. Only lower 2 bits are subtracted using 2-bit subtractor

        case (sel)
            2'b00: dout = mux_out0;
            2'b01: dout = mux_out1;
            2'b10: dout = mux_out2;
            default: dout = mux_out3;
        endcase
    end
endmodule