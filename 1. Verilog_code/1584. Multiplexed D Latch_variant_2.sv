//SystemVerilog
// Top-level module
module mux_d_latch_top (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    input wire enable,
    output wire q
);

    wire selected_d;
    
    // Instantiate the optimized multiplexer module
    mux_4to1_optimized mux_inst (
        .d_inputs(d_inputs),
        .select(select),
        .out(selected_d)
    );
    
    // Instantiate the optimized D-latch module
    d_latch_optimized latch_inst (
        .d(selected_d),
        .enable(enable),
        .q(q)
    );

endmodule

// Optimized 4:1 Multiplexer module
module mux_4to1_optimized (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    output wire out
);
    // Using assign statement instead of always block for better performance
    assign out = (select == 2'b00) ? d_inputs[0] :
                 (select == 2'b01) ? d_inputs[1] :
                 (select == 2'b10) ? d_inputs[2] :
                 (select == 2'b11) ? d_inputs[3] : 1'b0;
endmodule

// Optimized D-latch module
module d_latch_optimized (
    input wire d,
    input wire enable,
    output wire q
);
    // Using assign statement with conditional operator for better performance
    assign q = enable ? d : q;
endmodule

// Alternative implementation using gate-level primitives for area optimization
module d_latch_gate_level (
    input wire d,
    input wire enable,
    output wire q
);
    wire d_enabled, not_enable, feedback;
    
    // Gate-level implementation
    and(d_enabled, d, enable);
    not(not_enable, enable);
    and(feedback, q, not_enable);
    or(q, d_enabled, feedback);
endmodule

// Alternative implementation using transmission gates for power optimization
module d_latch_transmission (
    input wire d,
    input wire enable,
    output wire q
);
    wire not_enable;
    wire q_bar;
    
    // Transmission gate implementation
    not(not_enable, enable);
    tranif1(q, d, enable);
    tranif0(q, q, not_enable);
endmodule