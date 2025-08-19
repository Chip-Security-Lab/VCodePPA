//SystemVerilog

// Submodule for data capture
module data_capture #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg [DATA_WIDTH-1:0] data_a_out,
    output reg [DATA_WIDTH-1:0] data_b_out
);
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            data_a_out <= 0;
            data_b_out <= 0;
        end else if (enable) begin
            data_a_out <= data_in_a;
            data_b_out <= data_in_b;
        end
    end
endmodule

// Submodule for comparison logic
module comparison_logic #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_a,
    input wire [DATA_WIDTH-1:0] data_b,
    output wire is_equal
);
    assign is_equal = (data_a == data_b);
endmodule

// Top-level module
module param_equality_comparator_pipeline #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg match_flag
);

    // Internal wires
    wire [DATA_WIDTH-1:0] data_a_stage1, data_b_stage1;
    wire is_equal;

    // Instantiate data capture submodule
    data_capture #(.DATA_WIDTH(DATA_WIDTH)) data_capture_inst (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .data_in_a(data_in_a),
        .data_in_b(data_in_b),
        .data_a_out(data_a_stage1),
        .data_b_out(data_b_stage1)
    );

    // Instantiate comparison logic submodule
    comparison_logic #(.DATA_WIDTH(DATA_WIDTH)) comparison_logic_inst (
        .data_a(data_a_stage1),
        .data_b(data_b_stage1),
        .is_equal(is_equal)
    );

    // Registered output with enable control
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            match_flag <= 1'b0;
        end else if (enable) begin
            match_flag <= is_equal;
        end
    end
endmodule