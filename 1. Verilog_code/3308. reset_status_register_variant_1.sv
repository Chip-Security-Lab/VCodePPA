//SystemVerilog
// SystemVerilog
// Top-level reset status register module with Valid-Ready handshake
module reset_status_register_vr(
    input                     clk,
    input                     global_rst_n,

    // Valid-Ready handshake for input side
    input                     input_valid,
    output                    input_ready,
    input      [5:0]          reset_inputs_n,  // Active low inputs
    input      [5:0]          status_clear,

    // Valid-Ready handshake for output side
    output reg                output_valid,
    input                     output_ready,
    output reg [5:0]          reset_status
);

    // Internal signals
    wire   [5:0] active_resets;
    wire   [5:0] rising_edge_resets;
    wire   [5:0] status_reg_out;

    // Internal handshake registers
    reg           input_accepted;
    reg  [5:0]    reset_inputs_n_reg;
    reg  [5:0]    status_clear_reg;

    // Input handshake logic
    assign input_ready = !input_accepted;

    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            input_accepted     <= 1'b0;
            reset_inputs_n_reg <= 6'd0;
            status_clear_reg   <= 6'd0;
        end else if (input_valid && input_ready) begin
            input_accepted     <= 1'b1;
            reset_inputs_n_reg <= reset_inputs_n;
            status_clear_reg   <= status_clear;
        end else if (output_valid && output_ready) begin
            input_accepted     <= 1'b0;
        end
    end

    // Submodule: Active low to active high reset conversion
    active_reset_detector #(
        .WIDTH(6)
    ) u_active_reset_detector (
        .reset_inputs_n   (reset_inputs_n_reg),
        .active_resets    (active_resets)
    );

    // Submodule: Detect rising edge of reset signals
    rising_edge_detector #(
        .WIDTH(6)
    ) u_rising_edge_detector (
        .clk              (clk),
        .rst_n            (global_rst_n),
        .signal_in        (active_resets),
        .rising_edge      (rising_edge_resets)
    );

    // Submodule: Status register with clear and set logic
    status_register #(
        .WIDTH(6)
    ) u_status_register (
        .clk              (clk),
        .rst_n            (global_rst_n),
        .set_in           (rising_edge_resets),
        .clear_in         (status_clear_reg),
        .status_out       (status_reg_out)
    );

    // Output handshake logic
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            output_valid  <= 1'b0;
            reset_status  <= 6'd0;
        end else if (input_accepted && !output_valid) begin
            output_valid  <= 1'b1;
            reset_status  <= status_reg_out;
        end else if (output_valid && output_ready) begin
            output_valid  <= 1'b0;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: active_reset_detector
// Converts active low reset inputs to active high signals
// -----------------------------------------------------------------------------
module active_reset_detector #(
    parameter WIDTH = 6
)(
    input  [WIDTH-1:0] reset_inputs_n,
    output [WIDTH-1:0] active_resets
);
    assign active_resets = ~reset_inputs_n;
endmodule

// -----------------------------------------------------------------------------
// Submodule: rising_edge_detector
// Detects rising edges on each bit of the input signal
// -----------------------------------------------------------------------------
module rising_edge_detector #(
    parameter WIDTH = 6
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      signal_in,
    output reg [WIDTH-1:0]  rising_edge
);
    reg [WIDTH-1:0] prev_signal;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_signal <= {WIDTH{1'b0}};
            rising_edge <= {WIDTH{1'b0}};
        end else begin
            rising_edge <= signal_in & ~prev_signal;
            prev_signal <= signal_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: status_register
// Latches status bits on set, clears on clear input
// -----------------------------------------------------------------------------
module status_register #(
    parameter WIDTH = 6
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      set_in,
    input  [WIDTH-1:0]      clear_in,
    output reg [WIDTH-1:0]  status_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_out <= {WIDTH{1'b0}};
        end else begin
            status_out <= (status_out | set_in) & ~clear_in;
        end
    end
endmodule