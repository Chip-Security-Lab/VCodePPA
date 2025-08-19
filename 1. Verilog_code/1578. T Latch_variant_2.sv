//SystemVerilog
module t_latch_control (
    input wire t,
    input wire enable,
    output wire toggle_signal
);
    // Combinational logic
    assign toggle_signal = t & enable;
endmodule

module t_latch_state (
    input wire toggle_signal,
    output reg q
);
    // Sequential logic
    always @(posedge toggle_signal) begin
        q <= ~q;
    end
endmodule

module t_latch (
    input wire t,
    input wire enable,
    output wire q
);
    wire toggle_signal;
    
    // Instantiate control unit (combinational)
    t_latch_control control_unit (
        .t(t),
        .enable(enable),
        .toggle_signal(toggle_signal)
    );
    
    // Instantiate state unit (sequential) 
    t_latch_state state_unit (
        .toggle_signal(toggle_signal),
        .q(q)
    );
endmodule