//SystemVerilog
// Hierarchical version of StageEnabledShifter

module StageEnabledShifter #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire [WIDTH-1:0]      stage_en,
    input  wire                  serial_in,
    output wire [WIDTH-1:0]      parallel_out
);

    // Internal wires to connect submodules
    wire [WIDTH-1:0] stage_data;

    // -----------------------------------------------------------------------------
    // Submodule: ShiftRegisterStage
    // Function: Implements a single stage of the enabled shift register.
    // -----------------------------------------------------------------------------
    genvar i;
    generate
        // First stage: Loads serial_in
        ShiftRegisterStage #(
            .STAGE_INDEX(0)
        ) u_stage_0 (
            .clk        (clk),
            .en         (stage_en[0]),
            .data_in    (serial_in),
            .data_out   (stage_data[0])
        );

        // Remaining stages: Shift from previous stage
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_shift_stages
            ShiftRegisterStage #(
                .STAGE_INDEX(i)
            ) u_stage (
                .clk        (clk),
                .en         (stage_en[i]),
                .data_in    (stage_data[i-1]),
                .data_out   (stage_data[i])
            );
        end
    endgenerate

    // Output assignment
    assign parallel_out = stage_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: ShiftRegisterStage
// Function: Single bit register with enable and data input/output
// -----------------------------------------------------------------------------
module ShiftRegisterStage #(
    parameter STAGE_INDEX = 0
)(
    input  wire clk,
    input  wire en,
    input  wire data_in,
    output reg  data_out
);
    // Latch data_in into data_out on positive edge of clk if enabled
    always @(posedge clk) begin
        if (en) begin
            data_out <= data_in;
        end
    end
endmodule