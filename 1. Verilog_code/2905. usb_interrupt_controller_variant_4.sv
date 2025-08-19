//SystemVerilog
module usb_interrupt_controller #(
    parameter NUM_ENDPOINTS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [NUM_ENDPOINTS-1:0] ep_interrupt,
    input wire [NUM_ENDPOINTS-1:0] mask,
    input wire global_enable,
    input wire [NUM_ENDPOINTS-1:0] clear,
    output reg interrupt,
    output reg [NUM_ENDPOINTS-1:0] status
);
    reg [NUM_ENDPOINTS-1:0] pending;
    wire [NUM_ENDPOINTS-1:0] pending_next;
    wire [NUM_ENDPOINTS-1:0] status_next;
    wire interrupt_next;
    wire any_masked_pending;
    
    // 计算下一个pending值
    assign pending_next = (pending | ep_interrupt) & ~clear;
    
    // 计算状态寄存器
    assign status_next = pending_next & mask;
    
    // 检查是否有任何被屏蔽的中断处于等待状态
    assign any_masked_pending = |status_next;
    
    // 计算主中断信号
    assign interrupt_next = global_enable & any_masked_pending;
    
    // 更新pending寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            pending <= pending_next;
        end
    end
    
    // 更新status寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            status <= status_next;
        end
    end
    
    // 更新interrupt信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interrupt <= 1'b0;
        end else begin
            interrupt <= interrupt_next;
        end
    end
endmodule