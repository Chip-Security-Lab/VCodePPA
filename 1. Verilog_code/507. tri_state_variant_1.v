// Top level module
module tri_state_top(
    input data_in,
    input enable,
    output tri data_out
);

    // Internal signals
    wire data_valid;
    wire data_buffer;

    // Control logic submodule
    control_logic ctrl_inst(
        .enable(enable),
        .data_valid(data_valid)
    );

    // Data path submodule  
    data_path data_inst(
        .data_in(data_in),
        .data_valid(data_valid),
        .data_buffer(data_buffer)
    );

    // Output driver submodule
    output_driver out_inst(
        .data_buffer(data_buffer),
        .data_valid(data_valid),
        .data_out(data_out)
    );

endmodule

// Control logic submodule
module control_logic(
    input enable,
    output reg data_valid
);
    always @(*) begin
        data_valid = enable;
    end
endmodule

// Data path submodule
module data_path(
    input data_in,
    input data_valid,
    output reg data_buffer
);
    always @(*) begin
        case(data_valid)
            1'b1: data_buffer = data_in;
            1'b0: data_buffer = 1'b0;
            default: data_buffer = 1'b0;
        endcase
    end
endmodule

// Output driver submodule
module output_driver(
    input data_buffer,
    input data_valid,
    output tri data_out
);
    reg data_out_reg;
    always @(*) begin
        case(data_valid)
            1'b1: data_out_reg = data_buffer;
            1'b0: data_out_reg = 1'bz;
            default: data_out_reg = 1'bz;
        endcase
    end
    assign data_out = data_out_reg;
endmodule