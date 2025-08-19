//SystemVerilog
module CaseMux #(parameter N=4, DW=2) (
    input  [$clog2(N)-1:0] sel,
    input  [N-1:0][DW-1:0] din,
    output reg [DW-1:0] dout
);

    // Han-Carlson 2-bit adder for 2's complement subtraction
    function [DW-1:0] twos_complement_subtractor;
        input [DW-1:0] minuend;
        input [DW-1:0] subtrahend;
        reg   [DW-1:0] subtrahend_neg;
        reg   [DW-1:0] sum;
        reg   [1:0]    a, b;
        reg            c0, c1, c2;
        reg            g0, g1, p0, p1;
        reg            gl0, pl0, gl1, pl1;
        begin
            // Compute two's complement of subtrahend
            subtrahend_neg = {~subtrahend[1], ~subtrahend[0]} + 2'b01;

            a = minuend;
            b = subtrahend_neg;

            // Han-Carlson 2-bit adder logic
            // Generate and propagate
            g0 = a[0] & b[0];
            p0 = a[0] ^ b[0];
            g1 = a[1] & b[1];
            p1 = a[1] ^ b[1];

            // Pre-processing
            // Black cell: (G,P) = (g1 | (p1 & g0), p1 & p0)
            gl0 = g0;
            pl0 = p0;
            gl1 = g1 | (p1 & g0);
            pl1 = p1 & p0;

            // Carry chain
            c0 = 1'b0;
            c1 = gl0 | (pl0 & c0);
            c2 = gl1 | (pl1 & c0);

            // Sum
            sum[0] = a[0] ^ b[0] ^ c0;
            sum[1] = a[1] ^ b[1] ^ c1;

            twos_complement_subtractor = sum;
        end
    endfunction

    reg [DW-1:0] mux_data;
    reg [1:0]   operation_select;

    always @* begin
        case (sel)
            0: begin
                mux_data = din[0];
                operation_select   = 2'd0;
            end
            1: begin
                mux_data = din[1];
                operation_select   = 2'd0;
            end
            2: begin
                mux_data = din[2];
                operation_select   = 2'd1;
            end
            3: begin
                mux_data = din[3];
                operation_select   = 2'd0;
            end
            default: begin
                mux_data = din[sel];
                operation_select   = 2'd0;
            end
        endcase

        if (operation_select == 2'd1)
            dout = twos_complement_subtractor(din[2], din[1]);
        else
            dout = mux_data;
    end

endmodule