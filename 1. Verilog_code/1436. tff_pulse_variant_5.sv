//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module - T flip-flop with pulse trigger
module tff_pulse (
    input  wire clk,   // Clock input
    input  wire rstn,  // Active-low reset
    input  wire t,     // Toggle control
    output wire q      // Output state
);

    // Internal signals
    wire toggle_enable;
    wire next_state;
    wire current_state;

    // Combinational logic partition
    tff_comb_logic u_comb_logic (
        .t(t),
        .current_state(current_state),
        .toggle_enable(toggle_enable),
        .next_state(next_state)
    );

    // Sequential logic partition
    tff_seq_logic u_seq_logic (
        .clk(clk),
        .rstn(rstn),
        .next_state(next_state),
        .current_state(current_state)
    );

    // Output assignment
    assign q = current_state;

endmodule

// Combined combinational logic module
module tff_comb_logic (
    input  wire t,
    input  wire current_state,
    output wire toggle_enable,
    output wire next_state
);
    
    // Toggle detection logic
    assign toggle_enable = t;
    
    // Next state determination logic
    assign next_state = toggle_enable ? ~current_state : current_state;

endmodule

// Sequential logic module
module tff_seq_logic (
    input  wire clk,
    input  wire rstn,
    input  wire next_state,
    output reg  current_state
);
    
    // State register with synchronous reset
    always @(posedge clk) begin
        if (!rstn)
            current_state <= 1'b0;
        else
            current_state <= next_state;
    end

endmodule