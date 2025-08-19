//SystemVerilog
module bit_inverter (
    input wire data_in,
    output wire data_out
);
    assign data_out = ~data_in;
endmodule

module not_gate_10bit (
    input wire [9:0] A,
    output wire [9:0] Y
);

    // Instantiate 10 single-bit inverters
    bit_inverter bit_inverter_inst_0 (
        .data_in  (A[0]),
        .data_out (Y[0])
    );
    bit_inverter bit_inverter_inst_1 (
        .data_in  (A[1]),
        .data_out (Y[1])
    );
    bit_inverter bit_inverter_inst_2 (
        .data_in  (A[2]),
        .data_out (Y[2])
    );
    bit_inverter bit_inverter_inst_3 (
        .data_in  (A[3]),
        .data_out (Y[3])
    );
    bit_inverter bit_inverter_inst_4 (
        .data_in  (A[4]),
        .data_out (Y[4])
    );
    bit_inverter bit_inverter_inst_5 (
        .data_in  (A[5]),
        .data_out (Y[5])
    );
    bit_inverter bit_inverter_inst_6 (
        .data_in  (A[6]),
        .data_out (Y[6])
    );
    bit_inverter bit_inverter_inst_7 (
        .data_in  (A[7]),
        .data_out (Y[7])
    );
    bit_inverter bit_inverter_inst_8 (
        .data_in  (A[8]),
        .data_out (Y[8])
    );
    bit_inverter bit_inverter_inst_9 (
        .data_in  (A[9]),
        .data_out (Y[9])
    );

endmodule