//SystemVerilog
// 顶层模块
module counter_step #(parameter WIDTH=4, STEP=2) (
    input clk, rst_n,
    output [WIDTH-1:0] cnt
);
    // 内部连线
    wire [WIDTH-1:0] incremented_cnt;
    
    // 优化后的计数器寄存器子模块实例化
    optimized_counter_register #(.WIDTH(WIDTH), .STEP(STEP)) u_counter_register (
        .clk(clk),
        .rst_n(rst_n),
        .cnt(cnt)
    );
    
endmodule

// 优化后的计数器寄存器子模块 - 整合了存储和计数逻辑
module optimized_counter_register #(parameter WIDTH=4, STEP=2) (
    input clk,
    input rst_n,
    output reg [WIDTH-1:0] cnt
);
    wire [WIDTH-1:0] next_cnt;
    
    // 将计数逻辑直接合并到寄存器模块中
    assign next_cnt = cnt + STEP;
    
    always @(posedge clk) begin
        if (!rst_n)
            cnt <= {WIDTH{1'b0}};
        else
            cnt <= next_cnt;
    end
endmodule