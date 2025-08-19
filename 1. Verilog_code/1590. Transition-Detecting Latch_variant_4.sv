//SystemVerilog
// 顶层模块
module transition_detect_latch (
    input wire d,
    input wire enable,
    output reg q,
    output wire transition
);

    // 内部信号
    wire d_sync;
    wire enable_sync;
    wire q_latch;
    wire transition_detect;

    // 输入同步子模块
    input_sync sync_inst (
        .clk(clk),
        .rst_n(rst_n),
        .d_in(d),
        .enable_in(enable),
        .d_out(d_sync),
        .enable_out(enable_sync)
    );

    // 锁存器子模块
    latch_unit latch_inst (
        .d(d_sync),
        .enable(enable_sync),
        .q(q_latch)
    );

    // 边沿检测子模块
    edge_detector edge_inst (
        .d(d_sync),
        .enable(enable_sync),
        .transition(transition_detect)
    );

    // 输出寄存器子模块
    output_reg out_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .q_in(q_latch),
        .transition_in(transition_detect),
        .q_out(q),
        .transition_out(transition)
    );

endmodule

// 输入同步子模块
module input_sync (
    input wire clk,
    input wire rst_n,
    input wire d_in,
    input wire enable_in,
    output reg d_out,
    output reg enable_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_out <= 1'b0;
            enable_out <= 1'b0;
        end else begin
            d_out <= d_in;
            enable_out <= enable_in;
        end
    end

endmodule

// 锁存器子模块
module latch_unit (
    input wire d,
    input wire enable,
    output reg q
);

    always @* begin
        if (enable) begin
            q = d;
        end
    end

endmodule

// 边沿检测子模块
module edge_detector (
    input wire d,
    input wire enable,
    output wire transition
);

    reg d_prev;
    
    always @* begin
        if (enable) begin
            d_prev = d;
        end
    end
    
    assign transition = (d != d_prev) && enable;

endmodule

// 输出寄存器子模块
module output_reg (
    input wire clk,
    input wire rst_n,
    input wire q_in,
    input wire transition_in,
    output reg q_out,
    output reg transition_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out <= 1'b0;
            transition_out <= 1'b0;
        end else begin
            q_out <= q_in;
            transition_out <= transition_in;
        end
    end

endmodule