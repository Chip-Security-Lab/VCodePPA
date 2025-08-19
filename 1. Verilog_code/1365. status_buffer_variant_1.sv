//SystemVerilog
module status_buffer (
    input wire clk,
    input wire rst_n,
    input wire [7:0] status_in,
    input wire valid_in,
    output wire ready_out,
    input wire clear,
    output reg [7:0] status_out
);

    // 内部状态机状态
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    
    reg state, next_state;
    reg data_received;
    
    // 握手信号生成
    assign ready_out = (state == IDLE);
    
    // 状态机逻辑 - 使用条件运算符
    always @(posedge clk or negedge rst_n)
        state <= (!rst_n) ? IDLE : next_state;
    
    // 下一状态逻辑 - 使用条件运算符
    always @(*)
        next_state = (state == IDLE) ? ((valid_in && ready_out) ? BUSY : IDLE) : IDLE;
    
    // 数据接收标志 - 使用条件运算符
    always @(posedge clk or negedge rst_n)
        data_received <= (!rst_n) ? 1'b0 : ((state == IDLE && valid_in && ready_out) ? 1'b1 : 1'b0);
    
    // 数据处理逻辑 - 使用条件运算符
    always @(posedge clk or negedge rst_n)
        status_out <= (!rst_n) ? 8'b0 : (clear ? 8'b0 : (data_received ? (status_out | status_in) : status_out));
    
endmodule