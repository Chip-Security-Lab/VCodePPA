//SystemVerilog
// Top-level module: Hierarchical reset duration controller
module reset_duration_controller #(
    parameter MIN_DURATION = 16'd100,
    parameter MAX_DURATION = 16'd10000
)(
    input  wire        clk,
    input  wire        trigger,
    input  wire [15:0] requested_duration,
    output wire        reset_active
);

    // Internal signals for submodule connections
    wire [15:0] constrained_duration;
    wire [15:0] actual_duration;
    wire        reset_active_int;

    // Duration Constraint Submodule
    duration_constrainer #(
        .MIN_DURATION(MIN_DURATION),
        .MAX_DURATION(MAX_DURATION)
    ) u_duration_constrainer (
        .requested_duration(requested_duration),
        .constrained_duration(constrained_duration)
    );

    // Duration Register Submodule
    duration_register u_duration_register (
        .clk(clk),
        .constrained_duration(constrained_duration),
        .actual_duration(actual_duration)
    );

    // Reset Control Submodule
    reset_control u_reset_control (
        .clk(clk),
        .trigger(trigger),
        .actual_duration(actual_duration),
        .reset_active(reset_active_int)
    );

    assign reset_active = reset_active_int;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Duration Constrainer
// Function: Constrains the requested duration between MIN_DURATION and MAX_DURATION
// -----------------------------------------------------------------------------
module duration_constrainer #(
    parameter MIN_DURATION = 16'd100,
    parameter MAX_DURATION = 16'd10000
)(
    input  wire [15:0] requested_duration,
    output wire [15:0] constrained_duration
);
    assign constrained_duration = (requested_duration <= MIN_DURATION) ? MIN_DURATION :
                                  (requested_duration >= MAX_DURATION) ? MAX_DURATION :
                                  requested_duration;
endmodule

// -----------------------------------------------------------------------------
// Submodule: Duration Register
// Function: Registers the constrained duration on the rising edge of clk
// -----------------------------------------------------------------------------
module duration_register(
    input  wire        clk,
    input  wire [15:0] constrained_duration,
    output reg  [15:0] actual_duration
);
    always @(posedge clk) begin
        actual_duration <= constrained_duration;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Reset Control
// Function: Controls the reset_active signal and internal counter
// -----------------------------------------------------------------------------
module reset_control(
    input  wire        clk,
    input  wire        trigger,
    input  wire [15:0] actual_duration,
    output reg         reset_active
);
    reg [15:0] counter = 16'd0;

    always @(posedge clk) begin
        if (trigger && !reset_active) begin
            reset_active <= 1'b1;
            counter <= 16'd0;
        end else if (reset_active) begin
            if (counter == actual_duration - 1) begin
                reset_active <= 1'b0;
            end else begin
                counter <= counter + 16'd1;
            end
        end
    end
endmodule