//SystemVerilog
module error_detect_mux(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input valid_a, valid_b, valid_c, valid_d,
    output [7:0] out_data,
    output error_flag
);

    // Data selection submodule
    data_selector data_sel_inst(
        .in_a(in_a),
        .in_b(in_b),
        .in_c(in_c),
        .in_d(in_d),
        .select(select),
        .out_data(out_data)
    );

    // Error detection submodule
    error_detector error_det_inst(
        .valid_a(valid_a),
        .valid_b(valid_b),
        .valid_c(valid_c),
        .valid_d(valid_d),
        .select(select),
        .error_flag(error_flag)
    );

endmodule

// Data selection submodule
module data_selector(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    output reg [7:0] out_data
);
    // Data selection logic - selects one of four inputs based on select signal
    always @(*) begin
        case (select)
            2'b00: out_data = in_a;
            2'b01: out_data = in_b;
            2'b10: out_data = in_c;
            2'b11: out_data = in_d;
            default: out_data = 8'h00; // Default case for synthesis safety
        endcase
    end
endmodule

// Error detection submodule
module error_detector(
    input valid_a, valid_b, valid_c, valid_d,
    input [1:0] select,
    output reg error_flag
);
    // Error detection logic - checks if selected input is valid
    always @(*) begin
        case (select)
            2'b00: error_flag = !valid_a;
            2'b01: error_flag = !valid_b;
            2'b10: error_flag = !valid_c;
            2'b11: error_flag = !valid_d;
            default: error_flag = 1'b1; // Default case for synthesis safety
        endcase
    end
endmodule