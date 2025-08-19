module basic_1to2_demux (
    input wire data_in,          // Input data to be routed
    input wire sel,              // Selection line
    output wire out0, out1       // Output lines
);
    // Simple conditional assignment for routing
    assign out0 = (sel == 1'b0) ? data_in : 1'b0;
    assign out1 = (sel == 1'b1) ? data_in : 1'b0;
endmodule