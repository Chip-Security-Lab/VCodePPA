//SystemVerilog
module basic_sync_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire req,       // 替代 write_en (valid信号)
    output reg ack,       // 替代 ready信号
    output reg [7:0] data_out
);
    // 使用单一状态寄存器
    reg buffer_state;
    
    localparam IDLE = 1'b0;
    localparam READY = 1'b1;
    
    always @(posedge clk) begin
        case (buffer_state)
            IDLE: begin
                if (req) begin
                    // 接收新数据
                    data_out <= data_in;
                    buffer_state <= READY;
                    ack <= 1'b1;
                end
                else begin
                    ack <= 1'b0;
                end
            end
            
            READY: begin
                // 自动返回到IDLE状态
                buffer_state <= IDLE;
                ack <= 1'b0;
            end
        endcase
    end
endmodule