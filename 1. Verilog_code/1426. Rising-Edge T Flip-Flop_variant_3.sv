//SystemVerilog
// Top level module
module rising_edge_t_ff (
    input wire clk,
    input wire t,
    output wire q
);
    // Internal signals for connecting submodules
    wire t_edge_detected;
    wire q_internal;
    
    // Edge detector submodule instance
    edge_detector u_edge_detector (
        .clk(clk),
        .signal_in(t),
        .rising_edge_detected(t_edge_detected)
    );
    
    // T flip-flop core submodule instance
    t_flip_flop_core u_t_flip_flop (
        .clk(clk),
        .toggle_enable(t_edge_detected),
        .q_out(q_internal)
    );
    
    // Output assignment
    assign q = q_internal;
    
endmodule

// Submodule for detecting rising edges on input signal
module edge_detector (
    input wire clk,
    input wire signal_in,
    output reg rising_edge_detected
);
    reg signal_prev;
    
    always @(posedge clk) begin
        signal_prev <= signal_in;
        rising_edge_detected <= !signal_prev && signal_in;
    end
endmodule

// Submodule implementing the core T flip-flop functionality
module t_flip_flop_core (
    input wire clk,
    input wire toggle_enable,
    output reg q_out
);
    initial begin
        q_out = 1'b0; // 初始化输出
    end
    
    always @(posedge clk) begin
        if (toggle_enable)
            q_out <= ~q_out;
    end
endmodule