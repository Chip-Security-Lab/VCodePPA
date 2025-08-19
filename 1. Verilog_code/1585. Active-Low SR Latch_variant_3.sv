//SystemVerilog
module sr_latch_active_low (
    input wire s_n,      // Active-low set
    input wire r_n,      // Active-low reset
    output wire q,
    output wire q_bar
);

    // Internal signals
    wire q_internal;
    
    // Latch core module
    sr_latch_core latch_core (
        .s_n(s_n),
        .r_n(r_n),
        .q(q_internal)
    );
    
    // Output buffer module
    output_buffer out_buf (
        .q_in(q_internal),
        .q(q),
        .q_bar(q_bar)
    );

endmodule

module sr_latch_core (
    input wire s_n,
    input wire r_n,
    output reg q
);
    always @* begin
        q = (!s_n & r_n) | (q & s_n);
    end
endmodule

module output_buffer (
    input wire q_in,
    output wire q,
    output wire q_bar
);
    assign q = q_in;
    assign q_bar = ~q_in;
endmodule