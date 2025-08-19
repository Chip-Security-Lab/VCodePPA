//SystemVerilog
//-----------------------------------------------------------------------------
// Project: Pipelined Register Architecture
// Module:  pl_reg_latch_top
// Description: Top-level module for parameterized register latch
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module pl_reg_latch_top #(
    parameter W = 8
)(
    input  wire        clk,         // Clock signal
    input  wire        rst_n,       // Active-low reset
    input  wire        gate,        // Gate control signal
    input  wire        load,        // Load control signal
    input  wire [W-1:0] d,          // Data input
    output wire [W-1:0] q           // Data output
);

    // Internal signals
    wire ctrl_enable;
    wire [W-1:0] staged_data;

    // Control unit handles timing and control logic
    pl_reg_control_logic u_control (
        .clk        (clk),
        .rst_n      (rst_n),
        .gate       (gate),
        .load       (load),
        .enable     (ctrl_enable)
    );

    // Data staging unit for processing input data
    pl_reg_data_stage #(
        .WIDTH      (W)
    ) u_data_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (ctrl_enable),
        .data_in    (d),
        .data_out   (staged_data)
    );

    // Output unit provides registered output with isolation
    pl_reg_output_unit #(
        .WIDTH      (W)
    ) u_output (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (staged_data),
        .data_out   (q)
    );

endmodule

//-----------------------------------------------------------------------------
// Module:  pl_reg_control_logic
// Description: Enhanced control logic with clock synchronization
//-----------------------------------------------------------------------------
module pl_reg_control_logic (
    input  wire clk,
    input  wire rst_n,
    input  wire gate,
    input  wire load,
    output reg  enable
);

    // Internal signals for edge detection
    reg gate_r, load_r;
    wire gate_valid, load_valid;

    // Register inputs for edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gate_r <= 1'b0;
            load_r <= 1'b0;
        end else begin
            gate_r <= gate;
            load_r <= load;
        end
    end

    // Detect valid control conditions
    assign gate_valid = gate & gate_r;
    assign load_valid = load & load_r;

    // Generate synchronized enable signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable <= 1'b0;
        end else begin
            enable <= gate_valid & load_valid;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Module:  pl_reg_data_stage
// Description: Data processing stage with optional transformation
//-----------------------------------------------------------------------------
module pl_reg_data_stage #(
    parameter WIDTH = 8
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire                enable,
    input  wire [WIDTH-1:0]    data_in,
    output reg  [WIDTH-1:0]    data_out
);

    // Internal pipeline register
    reg [WIDTH-1:0] data_pipe;

    // First stage: capture input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe <= {WIDTH{1'b0}};
        end else if (enable) begin
            data_pipe <= data_in;
        end
    end

    // Second stage: process data (currently pass-through)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_pipe;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Module:  pl_reg_output_unit
// Description: Output buffer with isolation and stability features
//-----------------------------------------------------------------------------
module pl_reg_output_unit #(
    parameter WIDTH = 8
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]    data_in,
    output reg  [WIDTH-1:0]    data_out
);

    // Registered output for stability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end

endmodule