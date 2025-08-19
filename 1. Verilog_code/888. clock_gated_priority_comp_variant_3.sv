//SystemVerilog
module clock_gated_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n, enable,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Clock gating logic (组合逻辑部分)
    wire gated_clk;
    reg enable_latch;
    
    // 时序逻辑：enable latch
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_latch <= 1'b0;
        else
            enable_latch <= enable;
    end
    
    // 组合逻辑：clock gating
    assign gated_clk = clk & enable_latch;
    
    // 组合逻辑：优先级编码器
    wire [$clog2(WIDTH)-1:0] priority_next;
    priority_encoder #(.WIDTH(WIDTH)) priority_enc (
        .data_in(data_in),
        .priority_out(priority_next)
    );
    
    // 时序逻辑：更新输出寄存器
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= priority_next;
        end
    end
endmodule

// 独立的组合逻辑模块：优先级编码器
module priority_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // 纯组合逻辑实现优先级编码
    always @(*) begin
        priority_out = 0;
        for (integer i = WIDTH-1; i >= 0; i = i - 1)
            if (data_in[i]) priority_out = i[$clog2(WIDTH)-1:0];
    end
endmodule