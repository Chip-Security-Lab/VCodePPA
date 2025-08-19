//SystemVerilog
// Top-level module: Hierarchical implementation of arithmetic right shifter (retimed, fanout-optimized)
module shift_right_arithmetic #(parameter WIDTH=8) (
    input  wire                   clk,
    input  wire                   en,
    input  wire signed [WIDTH-1:0] data_in,
    input  wire [2:0]             shift,
    output reg  signed [WIDTH-1:0] data_out
);

    // Buffer registers for high-fanout input signals
    reg signed [WIDTH-1:0] data_in_buf1, data_in_buf2;
    reg [2:0] shift_buf1, shift_buf2;
    reg en_buf1, en_buf2;

    // Buffer register for shifter output
    reg signed [WIDTH-1:0] shifter_output_buf1, shifter_output_buf2;

    // First stage: buffer inputs
    always @(posedge clk) begin
        data_in_buf1 <= data_in;
        shift_buf1   <= shift;
        en_buf1      <= en;
    end

    // Second stage: further buffer inputs for load balancing
    always @(posedge clk) begin
        data_in_buf2 <= data_in_buf1;
        shift_buf2   <= shift_buf1;
        en_buf2      <= en_buf1;
    end

    // Shifter output
    wire signed [WIDTH-1:0] shifter_output_wire;

    // Combinational arithmetic right shift (input from buffered signals)
    shift_right_arithmetic_logic #(.WIDTH(WIDTH)) u_shifter (
        .data_in (data_in_buf2),
        .shift   (shift_buf2),
        .data_out(shifter_output_wire)
    );

    // Buffer the shifter output to reduce fanout to data_out and other logic
    always @(posedge clk) begin
        shifter_output_buf1 <= shifter_output_wire;
    end

    always @(posedge clk) begin
        shifter_output_buf2 <= shifter_output_buf1;
    end

    // Output register with enable, using buffered enable and output signals
    always @(posedge clk) begin
        if (en_buf2)
            data_out <= shifter_output_buf2;
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Combinational arithmetic right shifter logic
// Performs signed arithmetic right shift based on shift amount
// -----------------------------------------------------------------------------
module shift_right_arithmetic_logic #(parameter WIDTH=8) (
    input  wire signed [WIDTH-1:0] data_in,
    input  wire [2:0]              shift,
    output wire signed [WIDTH-1:0] data_out
);
    assign data_out = data_in >>> shift;
endmodule