module async_right_shifter (
    input data_in,
    input [3:0] control,
    output data_out
);
    wire [4:0] internal;
    
    assign internal[4] = data_in;
    assign internal[3] = control[3] ? internal[4] : 1'bz;
    assign internal[2] = control[2] ? internal[3] : 1'bz;
    assign internal[1] = control[1] ? internal[2] : 1'bz;
    assign internal[0] = control[0] ? internal[1] : 1'bz;
    assign data_out = internal[0];
endmodule