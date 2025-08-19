//SystemVerilog
// Top level module
module EdgeDetectLatch (
    input wire clk,
    input wire sig_in,
    output wire rising,
    output wire falling
);

    // Internal signals
    wire sig_in_buf;
    wire last_sig;
    
    // Input buffer module
    InputBuffer u_input_buffer (
        .clk(clk),
        .sig_in(sig_in),
        .sig_out(sig_in_buf)
    );
    
    // Delay register module  
    DelayReg u_delay_reg (
        .clk(clk),
        .sig_in(sig_in_buf),
        .sig_out(last_sig)
    );
    
    // Edge detection module
    EdgeDetector u_edge_detector (
        .sig_in(sig_in_buf),
        .last_sig(last_sig),
        .rising(rising),
        .falling(falling)
    );

endmodule

// Input buffer module
module InputBuffer (
    input wire clk,
    input wire sig_in,
    output reg sig_out
);
    always @(posedge clk) begin
        sig_out <= sig_in;
    end
endmodule

// Delay register module
module DelayReg (
    input wire clk,
    input wire sig_in,
    output reg sig_out
);
    always @(posedge clk) begin
        sig_out <= sig_in;
    end
endmodule

// Edge detection module
module EdgeDetector (
    input wire sig_in,
    input wire last_sig,
    output reg rising,
    output reg falling
);
    always @(*) begin
        rising = sig_in & ~last_sig;
        falling = ~sig_in & last_sig;
    end
endmodule