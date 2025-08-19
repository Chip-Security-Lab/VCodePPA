module mux_shift #(parameter W=8) (
    input [W-1:0] din,
    input [1:0] sel,
    output [W-1:0] dout
);
assign dout = (sel == 0) ? din :
              (sel == 1) ? {din[6:0], 1'b0} :
              (sel == 2) ? {din[5:0], 2'b00} :
                           {din[3:0], 4'b0000};
endmodule