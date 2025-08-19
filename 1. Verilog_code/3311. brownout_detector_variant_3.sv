//SystemVerilog
// Top-level brownout detector module with hierarchical structure
module brownout_detector #(
    parameter LOW_THRESHOLD  = 8'd85,
    parameter HIGH_THRESHOLD = 8'd95
)(
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  supply_voltage,
    output wire        brownout_reset
);

    wire threshold_low_signal;
    wire threshold_high_signal;
    wire brownout_state_signal;

    // Voltage Comparator Submodule
    voltage_compare #(
        .LOW_THRESHOLD(LOW_THRESHOLD),
        .HIGH_THRESHOLD(HIGH_THRESHOLD)
    ) u_voltage_compare (
        .supply_voltage(supply_voltage),
        .threshold_low(threshold_low_signal),
        .threshold_high(threshold_high_signal)
    );

    // Brownout State Control Submodule
    brownout_state_ctrl u_brownout_state_ctrl (
        .clk(clk),
        .enable(enable),
        .threshold_low(threshold_low_signal),
        .threshold_high(threshold_high_signal),
        .brownout_state(brownout_state_signal)
    );

    // Output logic
    assign brownout_reset = brownout_state_signal;

endmodule

// ---------------------------------------------------------------------------
// Submodule: voltage_compare
// Compares the supply voltage against low and high thresholds.
// Outputs threshold_low (1 if below LOW_THRESHOLD), threshold_high (1 if above HIGH_THRESHOLD)
// ---------------------------------------------------------------------------
module voltage_compare #(
    parameter LOW_THRESHOLD  = 8'd85,
    parameter HIGH_THRESHOLD = 8'd95
)(
    input  wire [7:0] supply_voltage,
    output wire       threshold_low,
    output wire       threshold_high
);
    assign threshold_low  = (supply_voltage < LOW_THRESHOLD);
    assign threshold_high = (supply_voltage > HIGH_THRESHOLD);
endmodule

// ---------------------------------------------------------------------------
// Submodule: brownout_state_ctrl
// Controls the brownout state based on threshold crossings and enable signal.
// Implements brownout state as a synchronous register.
// ---------------------------------------------------------------------------
module brownout_state_ctrl (
    input  wire clk,
    input  wire enable,
    input  wire threshold_low,
    input  wire threshold_high,
    output reg  brownout_state
);
    typedef enum logic [1:0] {
        DISABLED      = 2'b00,
        BELOW_LOW     = 2'b01,
        ABOVE_HIGH    = 2'b10,
        WITHIN_RANGE  = 2'b11
    } voltage_status_t;

    voltage_status_t voltage_status;

    always_comb begin
        if (!enable)
            voltage_status = DISABLED;
        else if (threshold_low)
            voltage_status = BELOW_LOW;
        else if (threshold_high)
            voltage_status = ABOVE_HIGH;
        else
            voltage_status = WITHIN_RANGE;
    end

    always @(posedge clk) begin
        case (voltage_status)
            DISABLED:     brownout_state <= 1'b0;
            BELOW_LOW:    brownout_state <= 1'b1;
            ABOVE_HIGH:   brownout_state <= 1'b0;
            WITHIN_RANGE: brownout_state <= brownout_state;
            default:      brownout_state <= brownout_state;
        endcase
    end
endmodule