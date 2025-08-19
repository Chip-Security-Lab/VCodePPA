//SystemVerilog
// 顶层模块
module rising_edge_t_ff (
    input  wire clk,
    input  wire t,
    output wire q
);
    // 内部信号定义
    wire edge_detected;
    
    // 实例化子模块
    edge_detector u_edge_detector (
        .clk           (clk),
        .signal        (t),
        .rising_edge   (edge_detected)
    );
    
    toggle_flip_flop u_toggle_flip_flop (
        .clk           (clk),
        .toggle_enable (edge_detected),
        .q             (q)
    );
    
endmodule

// 边沿检测子模块
module edge_detector (
    input  wire clk,
    input  wire signal,
    output wire rising_edge
);
    reg signal_prev;
    
    always @(posedge clk) begin
        signal_prev <= signal;
    end
    
    assign rising_edge = signal && !signal_prev;
    
endmodule

// T触发器核心子模块
module toggle_flip_flop (
    input  wire clk,
    input  wire toggle_enable,
    output reg  q
);
    
    always @(posedge clk) begin
        if (toggle_enable)
            q <= ~q;
    end
    
endmodule