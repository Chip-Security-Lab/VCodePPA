//SystemVerilog
module transition_detect_latch (
    input wire d,
    input wire enable,
    output wire q,
    output wire transition
);

    // 实例化锁存器子模块
    latch_unit latch_inst (
        .d(d),
        .enable(enable),
        .q(q)
    );

    // 实例化边沿检测子模块
    edge_detector edge_det_inst (
        .d(d),
        .enable(enable),
        .transition(transition)
    );

endmodule

// 锁存器子模块
module latch_unit (
    input wire d,
    input wire enable,
    output reg q
);
    always @(posedge enable) begin
        q <= d;
    end
endmodule

// 边沿检测子模块
module edge_detector (
    input wire d,
    input wire enable,
    output wire transition
);
    reg d_prev;
    
    always @(posedge enable) begin
        d_prev <= d;
    end
    
    assign transition = enable & (d ^ d_prev);
endmodule