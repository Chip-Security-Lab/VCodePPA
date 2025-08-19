//SystemVerilog
// 顶层模块
module counter_ring #(parameter DEPTH=4) (
    input clk, rst_n,
    output [DEPTH-1:0] ring
);
    wire [DEPTH-1:0] ring_next;
    wire valid_pipeline;

    // 子模块实例化
    ring_shift_logic #(
        .DEPTH(DEPTH)
    ) shift_logic_inst (
        .ring_current(ring),
        .ring_next(ring_next)
    );

    pipeline_control pipeline_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_pipeline(valid_pipeline)
    );

    output_register #(
        .DEPTH(DEPTH)
    ) output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_pipeline(valid_pipeline),
        .ring_next(ring_next),
        .ring(ring)
    );

endmodule

// 环形移位逻辑子模块
module ring_shift_logic #(parameter DEPTH=4) (
    input [DEPTH-1:0] ring_current,
    output reg [DEPTH-1:0] ring_next
);
    // 实现环形移位逻辑
    always @(*) begin
        // 左移并将最高位移至最低位
        ring_next = {ring_current[DEPTH-2:0], ring_current[DEPTH-1]};
    end
endmodule

// 流水线控制子模块
module pipeline_control (
    input clk, rst_n,
    output reg valid_pipeline
);
    // 管道控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipeline <= 1'b0;
        end else begin
            valid_pipeline <= 1'b1;
        end
    end
endmodule

// 输出寄存器子模块
module output_register #(parameter DEPTH=4) (
    input clk, rst_n,
    input valid_pipeline,
    input [DEPTH-1:0] ring_next,
    output reg [DEPTH-1:0] ring
);
    // 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring <= {{1'b1}, {(DEPTH-1){1'b0}}};
        end else if (valid_pipeline) begin
            ring <= ring_next;
        end
    end
endmodule