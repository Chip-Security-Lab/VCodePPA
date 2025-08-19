//SystemVerilog
module delayed_write_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire trigger,
    output reg [15:0] data_out
);
    reg [15:0] buffer;
    reg write_pending;
    
    // 状态变量的流水线实现
    reg [1:0] state_pipe1;
    reg [1:0] state;
    reg [15:0] data_in_pipe1;
    
    // 第一级流水线 - 计算状态和缓存输入
    always @(posedge clk) begin
        state_pipe1 <= {trigger, write_pending};
        data_in_pipe1 <= data_in;
    end
    
    // 第二级流水线 - 基于缓存的状态执行操作
    always @(posedge clk) begin
        case (state_pipe1)
            2'b10: begin // trigger=1, write_pending=0
                buffer <= data_in_pipe1;
                write_pending <= 1'b1;
            end
            2'b11: begin // trigger=1, write_pending=1
                buffer <= data_in_pipe1;
                write_pending <= 1'b1;
            end
            2'b01: begin // trigger=0, write_pending=1
                data_out <= buffer;
                write_pending <= 1'b0;
            end
            2'b00: begin // trigger=0, write_pending=0
                // 保持当前状态
            end
            default: begin
                // 保持当前状态
            end
        endcase
    end
endmodule