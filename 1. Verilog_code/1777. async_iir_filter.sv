module async_iir_filter #(
    parameter DW = 14
)(
    input [DW-1:0] x_in,
    input [DW-1:0] y_prev,
    input [DW-1:0] a_coeff, b_coeff,
    output [DW-1:0] y_out
);
    // Simple first-order IIR: y[n] = a*x[n] + b*y[n-1]
    wire [2*DW-1:0] prod1, prod2;
    assign prod1 = a_coeff * x_in;
    assign prod2 = b_coeff * y_prev;
    assign y_out = prod1[2*DW-1:DW] + prod2[2*DW-1:DW];
endmodule
