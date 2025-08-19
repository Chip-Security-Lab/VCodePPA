//SystemVerilog
// Top level module
module dual_d_latch_top (
    input wire [1:0] d_in,
    input wire latch_enable,
    output wire [1:0] q_out
);

    // Internal signals
    wire [1:0] latch_out;
    
    // Instantiate individual D-latches
    d_latch_bit bit0 (
        .d(d_in[0]),
        .latch_enable(latch_enable),
        .q(latch_out[0])
    );
    
    d_latch_bit bit1 (
        .d(d_in[1]),
        .latch_enable(latch_enable),
        .q(latch_out[1])
    );
    
    // Output assignment
    assign q_out = latch_out;

endmodule

// Single bit D-latch module
module d_latch_bit (
    input wire d,
    input wire latch_enable,
    output reg q
);
    always @* begin
        if (latch_enable)
            q = d;
    end
endmodule