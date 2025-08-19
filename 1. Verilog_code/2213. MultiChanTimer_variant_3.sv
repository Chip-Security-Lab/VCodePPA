//SystemVerilog
// Top-level module
module MultiChanTimer #(
    parameter CH = 4,  // Number of channels
    parameter DW = 8   // Data width
)(
    input  wire        clk,      // System clock
    input  wire        rst_n,    // Active low reset
    input  wire [CH-1:0] chan_en,  // Channel enable signals
    output wire [CH-1:0] trig_out  // Trigger output signals
);

    // Interconnect wires
    wire [DW-1:0] count_values[0:CH-1];
    wire [CH-1:0] trigger_signals;

    // Instantiate channel timer modules
    genvar i;
    generate
        for(i = 0; i < CH; i = i + 1) begin : ch_inst
            TimerChannel #(
                .DW(DW)
            ) timer_channel_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enable(chan_en[i]),
                .trigger(trigger_signals[i]),
                .count_value(count_values[i])
            );
        end
    endgenerate

    // Instantiate trigger detector
    TriggerDetector #(
        .CH(CH),
        .DW(DW)
    ) trigger_detector_inst (
        .count_values(count_values),
        .trigger_out(trigger_signals)
    );

    // Connect internal trigger signals to output
    assign trig_out = trigger_signals;

endmodule

// Channel timer module - handles counter for each channel
module TimerChannel #(
    parameter DW = 8  // Data width
)(
    input  wire        clk,         // System clock
    input  wire        rst_n,       // Active low reset
    input  wire        enable,      // Channel enable
    input  wire        trigger,     // Trigger signal
    output reg  [DW-1:0] count_value  // Current count value
);

    // Control signals for case statement
    reg [1:0] timer_ctrl;

    // Define control signal
    always @(*) begin
        timer_ctrl = {!rst_n || trigger, enable};
    end

    // Counter logic with case statement
    always @(posedge clk) begin
        case(timer_ctrl)
            2'b10, 2'b11: count_value <= {DW{1'b0}};     // Reset or trigger (priority over enable)
            2'b01:        count_value <= count_value + 1'b1; // Enable and no reset/trigger
            2'b00:        count_value <= count_value;    // Hold value when not enabled
            default:      count_value <= {DW{1'b0}};     // Default case for safety
        endcase
    end

endmodule

// Trigger detector module - checks for maximum count value
module TriggerDetector #(
    parameter CH = 4,  // Number of channels
    parameter DW = 8   // Data width
)(
    input  wire [DW-1:0] count_values[0:CH-1],  // Count values from all channels
    output wire [CH-1:0] trigger_out            // Trigger outputs
);

    // Maximum value that triggers the output
    localparam [DW-1:0] MAX_COUNT = {DW{1'b1}};
    
    // Generate trigger signals
    genvar i;
    generate
        for(i = 0; i < CH; i = i + 1) begin : trig_gen
            assign trigger_out[i] = (count_values[i] == MAX_COUNT);
        end
    endgenerate

endmodule