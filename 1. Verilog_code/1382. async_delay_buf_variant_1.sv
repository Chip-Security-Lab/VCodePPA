//SystemVerilog
module async_delay_buf #(parameter DW=8, DEPTH=3) (
    input clk, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] buf_reg [0:DEPTH];
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [$clog2(DEPTH+1)-1:0] count; // 循环计数器
    
    // 状态转换逻辑
    always @(posedge clk) begin
        if (!en)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = en ? PROCESS : IDLE;
            PROCESS: next_state = (count == DEPTH-1) ? DONE : PROCESS;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理和计数逻辑
    always @(posedge clk) begin
        if (state == IDLE && en) begin
            buf_reg[0] <= data_in;
            count <= 0;
        end else if (state == PROCESS) begin
            buf_reg[count+1] <= buf_reg[count];
            count <= count + 1'b1;
        end else if (state == DONE) begin
            // 完成所有移位操作
        end
    end
    
    // 当处于IDLE状态且使能有效时，装载输入数据
    always @(posedge clk) begin
        if (state == IDLE && en) begin
            buf_reg[0] <= data_in;
        end
    end
    
    assign data_out = buf_reg[DEPTH];
endmodule