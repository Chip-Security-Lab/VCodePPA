module i2c_task_based #(
    parameter CMD_FIFO_DEPTH = 4
)(
    input clk,
    input rst_n,
    inout sda,
    inout scl,
    input cmd_valid,
    input [15:0] cmd_word,
    output reg cmd_ready
);
    // 基于任务的接口 - 将任务转换为可合成状态机
    localparam IDLE = 4'h0;
    localparam START = 4'h1;
    localparam ADDR = 4'h2;
    localparam DATA = 4'h3;
    localparam ACK = 4'h4;
    localparam STOP = 4'h5;
    localparam WAIT = 4'h6;
    
    reg [3:0] state;
    reg [7:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [2:0] bit_counter;
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // I2C总线驱动
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
    
    // 命令解析和状态机实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr_buffer <= 8'h0;
            data_buffer <= 8'h0;
            bit_counter <= 3'h0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            cmd_ready <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                    scl_oe <= 1'b0;
                    bit_counter <= 3'h0;
                    
                    if (cmd_valid) begin
                        cmd_ready <= 1'b0;
                        case (cmd_word[15:12])
                            4'h1: begin
                                // 开始传输命令
                                addr_buffer <= cmd_word[11:4];
                                data_buffer <= cmd_word[7:0];
                                state <= START;
                            end
                            // 其他命令...
                            default: begin
                                cmd_ready <= 1'b1; // 未知命令
                            end
                        endcase
                    end else begin
                        cmd_ready <= 1'b1;
                    end
                end
                
                START: begin
                    // 发送起始条件
                    sda_oe <= 1'b1;
                    scl_oe <= 1'b1;
                    scl_out <= 1'b1;
                    
                    sda_out <= 1'b0; // 发送起始位
                    state <= ADDR;
                end
                
                ADDR: begin
                    // 发送地址
                    sda_oe <= 1'b1;
                    scl_oe <= 1'b1;
                    
                    // 时钟控制
                    scl_out <= !scl_out;
                    
                    if (scl_out == 1'b0) begin
                        // SCL低电平时设置SDA
                        sda_out <= addr_buffer[7 - bit_counter];
                        
                        if (bit_counter == 3'h7) begin
                            bit_counter <= 3'h0;
                            state <= ACK;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                
                ACK: begin
                    // 等待ACK
                    scl_oe <= 1'b1;
                    
                    // 时钟控制
                    scl_out <= !scl_out;
                    
                    if (scl_out == 1'b0) begin
                        // 释放SDA总线以接收ACK
                        sda_oe <= 1'b0;
                        state <= DATA;
                    end
                end
                
                DATA: begin
                    // 发送数据
                    sda_oe <= 1'b1;
                    scl_oe <= 1'b1;
                    
                    // 时钟控制
                    scl_out <= !scl_out;
                    
                    if (scl_out == 1'b0) begin
                        // SCL低电平时设置SDA
                        sda_out <= data_buffer[7 - bit_counter];
                        
                        if (bit_counter == 3'h7) begin
                            bit_counter <= 3'h0;
                            state <= STOP;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                
                STOP: begin
                    // 发送停止条件
                    sda_oe <= 1'b1;
                    scl_oe <= 1'b1;
                    
                    scl_out <= 1'b1;
                    sda_out <= 1'b0;
                    
                    state <= WAIT;
                end
                
                WAIT: begin
                    // 完成停止条件
                    sda_out <= 1'b1;
                    state <= IDLE;
                    cmd_ready <= 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule