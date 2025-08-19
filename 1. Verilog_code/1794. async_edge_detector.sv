module async_edge_detector #(
    parameter EDGE_TYPE = "BOTH"  // "RISING", "FALLING", or "BOTH"
)(
    input signal,
    input prev_signal,
    output edge_detected
);
    wire rising_edge, falling_edge;
    
    assign rising_edge = signal & ~prev_signal;
    assign falling_edge = ~signal & prev_signal;
    
    generate
        if (EDGE_TYPE == "RISING")
            assign edge_detected = rising_edge;
        else if (EDGE_TYPE == "FALLING")
            assign edge_detected = falling_edge;
        else  // "BOTH"
            assign edge_detected = rising_edge | falling_edge;
    endgenerate
endmodule