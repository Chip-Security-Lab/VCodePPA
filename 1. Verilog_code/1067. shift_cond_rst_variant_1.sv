//SystemVerilog
// Top-level module: shift_cond_rst_pipeline
// Function: Structured pipelined conditional reset and shift register

module shift_cond_rst_pipeline #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  cond_rst,
    input  wire [WIDTH-1:0]      din,
    output wire [WIDTH-1:0]      dout
);

    // Stage 1: Input Register
    wire [WIDTH-1:0] stage1_data_in;
    input_register #(.WIDTH(WIDTH)) u_input_register (
        .clk(clk),
        .din(din),
        .dout(stage1_data_in)
    );

    // Stage 2: Shift Register Pipeline
    wire [WIDTH-1:0] stage2_shifted_data;
    shift_pipeline #(.WIDTH(WIDTH)) u_shift_pipeline (
        .clk(clk),
        .din(stage1_data_in),
        .dout(stage2_shifted_data)
    );

    // Stage 3: Conditional Reset Mux
    wire [WIDTH-1:0] stage3_mux_data;
    cond_mux_pipeline #(.WIDTH(WIDTH)) u_cond_mux_pipeline (
        .cond(cond_rst),
        .reset_val(stage1_data_in),
        .shift_val(stage2_shifted_data),
        .dout(stage3_mux_data)
    );

    // Stage 4: Output Register
    output_register #(.WIDTH(WIDTH)) u_output_register (
        .clk(clk),
        .din(stage3_mux_data),
        .dout(dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: input_register
// Description: Pipeline register for input data
// -----------------------------------------------------------------------------
module input_register #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire [WIDTH-1:0]      din,
    output reg  [WIDTH-1:0]      dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_pipeline
// Description: Two-stage pipelined left shift register, improves timing
// -----------------------------------------------------------------------------
module shift_pipeline #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire [WIDTH-1:0]      din,
    output wire [WIDTH-1:0]      dout
);

    reg [WIDTH-1:0] shift_stage1;
    reg [WIDTH-1:0] shift_stage2;

    // Stage 1: Register input and perform left shift, insert din[WIDTH-1] as MSB
    always @(posedge clk) begin
        shift_stage1[WIDTH-1] <= din[WIDTH-1];
        shift_stage1[WIDTH-2:0] <= din[WIDTH-2:0];
    end

    // Stage 2: Shift data left by one, propagate MSB
    always @(posedge clk) begin
        shift_stage2[WIDTH-1] <= shift_stage1[WIDTH-1];
        shift_stage2[WIDTH-2:0] <= shift_stage1[WIDTH-1:1];
    end

    assign dout = shift_stage2;

endmodule

// -----------------------------------------------------------------------------
// Submodule: cond_mux_pipeline
// Description: Pipeline register and conditional selection
// -----------------------------------------------------------------------------
module cond_mux_pipeline #(parameter WIDTH=8) (
    input  wire                  cond,
    input  wire [WIDTH-1:0]      reset_val,
    input  wire [WIDTH-1:0]      shift_val,
    output reg  [WIDTH-1:0]      dout
);
    always @(*) begin
        if (cond)
            dout = reset_val;
        else
            dout = shift_val;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: output_register
// Description: Output register to hold the current value of dout.
// -----------------------------------------------------------------------------
module output_register #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire [WIDTH-1:0]      din,
    output reg  [WIDTH-1:0]      dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule