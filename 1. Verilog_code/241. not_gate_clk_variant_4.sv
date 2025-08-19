//SystemVerilog
// SystemVerilog
// Submodule for input registration
module input_register (
    input wire clk,
    input wire data_in,
    output reg data_in_reg
);

    always @ (posedge clk) begin
        data_in_reg <= data_in;
    end

endmodule

// Submodule for NOT operation
module not_combinational (
    input wire data_in_reg,
    output wire not_operation_result
);

    assign not_operation_result = ~data_in_reg;

endmodule

// Submodule for output registration
module output_register (
    input wire clk,
    input wire not_operation_result,
    output reg data_out
);

    always @ (posedge clk) begin
        data_out <= not_operation_result;
    end

endmodule

// Top-level module
module not_gate_clk (
    input wire clk,
    input wire data_in,
    output wire data_out
);

    // Internal signals for connecting submodules
    wire data_in_registered;
    wire not_result_combinational;

    // Instantiate submodules
    input_register u_input_register (
        .clk(clk),
        .data_in(data_in),
        .data_in_reg(data_in_registered)
    );

    not_combinational u_not_combinational (
        .data_in_reg(data_in_registered),
        .not_operation_result(not_result_combinational)
    );

    output_register u_output_register (
        .clk(clk),
        .not_operation_result(not_result_combinational),
        .data_out(data_out)
    );

endmodule