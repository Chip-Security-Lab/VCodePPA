//SystemVerilog
// Top level module
module transition_detect_latch (
    input wire d,
    input wire enable,
    output reg q,
    output wire transition
);

    // Internal signals
    wire d_prev_reg;
    wire transition_detected;

    // Latch module instance
    data_latch u_data_latch (
        .d(d),
        .enable(enable),
        .q(q),
        .d_prev(d_prev_reg)
    );

    // Transition detection module instance  
    transition_detector u_transition_detector (
        .d(d),
        .d_prev(d_prev_reg),
        .enable(enable),
        .transition(transition)
    );

endmodule

// Data latch submodule
module data_latch (
    input wire d,
    input wire enable,
    output reg q,
    output reg d_prev
);

    always @(posedge enable) begin
        q <= d;
        d_prev <= d;
    end

endmodule

// Transition detection submodule
module transition_detector (
    input wire d,
    input wire d_prev,
    input wire enable,
    output wire transition
);

    assign transition = (d != d_prev) && enable;

endmodule