//SystemVerilog
// Top-level module: variable_step_shift
module variable_step_shift #(parameter W=8) (
    input  wire             clk,
    input  wire      [1:0]  step,
    input  wire [W-1:0]     din,
    output wire [W-1:0]     dout
);

    // Buffered input signals
    wire [W-1:0] din_buf1;
    wire [W-1:0] din_buf2;
    wire [W-1:0] din_buf3;
    wire [W-1:0] din_buf4;

    // Input Buffer Module: Reduces high fan-out from din signal
    input_buffer #(.W(W)) u_input_buffer (
        .clk      (clk),
        .din      (din),
        .din_buf1 (din_buf1),
        .din_buf2 (din_buf2),
        .din_buf3 (din_buf3),
        .din_buf4 (din_buf4)
    );

    // Step Shift Logic Module: Performs variable step shift
    step_shift_logic #(.W(W)) u_step_shift_logic (
        .clk      (clk),
        .step     (step),
        .din_buf1 (din_buf1),
        .din_buf2 (din_buf2),
        .din_buf3 (din_buf3),
        .din_buf4 (din_buf4),
        .dout     (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Input Buffer Module
// Latches the din input into four parallel registers to reduce fan-out.
// -----------------------------------------------------------------------------
module input_buffer #(parameter W=8) (
    input  wire         clk,
    input  wire [W-1:0] din,
    output reg  [W-1:0] din_buf1,
    output reg  [W-1:0] din_buf2,
    output reg  [W-1:0] din_buf3,
    output reg  [W-1:0] din_buf4
);
    always @(posedge clk) begin
        din_buf1 <= din;
        din_buf2 <= din;
        din_buf3 <= din;
        din_buf4 <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// Step Shift Logic Module
// Selects and shifts the buffered data based on the step control.
// -----------------------------------------------------------------------------
module step_shift_logic #(parameter W=8) (
    input  wire         clk,
    input  wire [1:0]   step,
    input  wire [W-1:0] din_buf1,
    input  wire [W-1:0] din_buf2,
    input  wire [W-1:0] din_buf3,
    input  wire [W-1:0] din_buf4,
    output reg  [W-1:0] dout
);
    always @(posedge clk) begin
        case(step)
            2'd0: dout <= din_buf1;
            2'd1: dout <= {din_buf2[W-2:0], 1'b0};
            2'd2: dout <= {din_buf3[W-3:0], 2'b00};
            2'd3: dout <= {din_buf4[W-5:0], 4'b0000};
            default: dout <= {W{1'b0}};
        endcase
    end
endmodule