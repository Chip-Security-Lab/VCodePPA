//SystemVerilog
module edge_sensitive_clock_gate (
    input  wire clk_in,
    input  wire data_valid,
    input  wire rst_n,
    output wire clk_out
);
    // 内部信号声明
    wire edge_detected;
    reg  data_valid_last;
    
    // 时序逻辑模块实例化
    edge_detector_seq seq_logic (
        .clk_in        (clk_in),
        .rst_n         (rst_n),
        .data_valid    (data_valid),
        .data_valid_ff (data_valid_last)
    );
    
    // 组合逻辑模块实例化
    edge_detector_comb comb_logic (
        .data_valid    (data_valid),
        .data_valid_ff (data_valid_last),
        .clk_in        (clk_in),
        .edge_detected (edge_detected),
        .clk_out       (clk_out)
    );
endmodule

// 时序逻辑模块
module edge_detector_seq (
    input  wire clk_in,
    input  wire rst_n,
    input  wire data_valid,
    output reg  data_valid_ff
);
    // 时序逻辑部分 - 仅在时钟边沿触发
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            data_valid_ff <= 1'b0;
        else
            data_valid_ff <= data_valid;
    end
endmodule

// 组合逻辑模块
module edge_detector_comb (
    input  wire data_valid,
    input  wire data_valid_ff,
    input  wire clk_in,
    output wire edge_detected,
    output wire clk_out
);
    // 组合逻辑部分 - 使用assign语句
    assign edge_detected = data_valid & ~data_valid_ff;
    assign clk_out = clk_in & edge_detected;
endmodule