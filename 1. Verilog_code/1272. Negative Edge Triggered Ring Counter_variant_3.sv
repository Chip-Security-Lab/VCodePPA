//SystemVerilog
`timescale 1ns / 1ps
module neg_edge_ring_counter #(
    parameter BITS = 4,
    parameter INIT_VALUE = 1  // 可配置初始值
)(
    input wire clk,            // 时钟信号
    input wire rst_n,          // 低电平有效的异步复位信号
    output wire [BITS-1:0] state // 计数器状态输出
);

    // 初始值和复位值
    localparam [BITS-1:0] RESET_STATE = {{(BITS-1){1'b0}}, 1'b1};

    // 内部状态寄存器
    reg [BITS-1:0] state_reg;
    
    // 缓冲寄存器组，用于分散state的扇出负载
    reg [BITS-1:0] state_buf1;
    reg [BITS-1:0] state_buf2;
    
    // 将内部状态连接到输出
    assign state = state_buf2;
    
    // 初始化状态
    initial begin
        state_reg = RESET_STATE;
        state_buf1 = RESET_STATE;
        state_buf2 = RESET_STATE;
    end
    
    // 在时钟负边沿或复位时更新状态
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= RESET_STATE;
        end else begin
            state_reg <= {state_reg[BITS-2:0], state_reg[BITS-1]};
        end
    end
    
    // 第一级缓冲寄存器
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_buf1 <= RESET_STATE;
        end else begin
            state_buf1 <= state_reg;
        end
    end
    
    // 第二级缓冲寄存器
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_buf2 <= RESET_STATE;
        end else begin
            state_buf2 <= state_buf1;
        end
    end

endmodule