module tri_state(
    input data_in, enable,
    output tri data_out
);
    assign data_out = enable ? data_in : 1'bz;
endmodule