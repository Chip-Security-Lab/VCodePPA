//SystemVerilog
// Top level module
module EdgeDetectLatch (
    input clk,
    input sig_in,
    output rising,
    output falling
);

    // Internal signals
    wire last_sig;
    
    // Submodule for signal storage
    SignalStorage signal_storage (
        .clk(clk),
        .sig_in(sig_in),
        .last_sig(last_sig)
    );
    
    // Submodule for edge detection
    EdgeDetection edge_detection (
        .sig_in(sig_in),
        .last_sig(last_sig),
        .rising(rising),
        .falling(falling)
    );

endmodule

// Submodule for storing previous signal value
module SignalStorage (
    input clk,
    input sig_in,
    output reg last_sig
);

    always @(posedge clk) begin
        last_sig <= sig_in;
    end

endmodule

// Submodule for detecting edges
module EdgeDetection (
    input sig_in,
    input last_sig,
    output reg rising,
    output reg falling
);

    always @(*) begin
        rising = sig_in & ~last_sig;
        falling = ~sig_in & last_sig;
    end

endmodule