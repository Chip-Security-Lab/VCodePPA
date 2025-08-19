//SystemVerilog
// Top level module
module sr_latch_active_low (
    input wire s_n,      // Active-low set
    input wire r_n,      // Active-low reset
    output wire q,
    output wire q_bar
);

    // Internal signals
    wire q_next;
    
    // State transition logic module
    state_transition_logic state_logic (
        .s_n(s_n),
        .r_n(r_n),
        .q_current(q),
        .q_next(q_next)
    );
    
    // State register module
    state_register state_reg (
        .q_next(q_next),
        .q(q)
    );
    
    // Output logic module
    output_logic out_logic (
        .q(q),
        .q_bar(q_bar)
    );

endmodule

// State transition logic module
module state_transition_logic (
    input wire s_n,
    input wire r_n,
    input wire q_current,
    output reg q_next
);
    always @* begin
        case ({s_n, r_n})
            2'b01:   q_next = 1'b1;  // !s_n && r_n
            2'b10:   q_next = 1'b0;  // s_n && !r_n
            default: q_next = q_current; // Hold state
        endcase
    end
endmodule

// State register module
module state_register (
    input wire q_next,
    output reg q
);
    always @* begin
        q = q_next;
    end
endmodule

// Output logic module
module output_logic (
    input wire q,
    output wire q_bar
);
    assign q_bar = ~q;
endmodule