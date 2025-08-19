//SystemVerilog
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
    
    // 状态机寄存器
    reg [3:0] state;
    reg [7:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [2:0] bit_counter;
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // 高扇出信号缓冲 - 优化缓冲器数量
    reg [15:0] cmd_word_buf;
    reg [3:0] idle_state_buf;
    reg [2:0] bit_counter_buf;
    reg [1:0] scl_out_pipe;
    
    // I2C总线驱动
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out_pipe[1] : 1'bz;
    
    // 优化的高扇出信号缓冲器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_word_buf <= 16'h0;
            idle_state_buf <= 4'h0;
            bit_counter_buf <= 3'h0;
            scl_out_pipe <= 2'b11;
        end else begin
            // 合并命令字缓冲
            cmd_word_buf <= cmd_word;
            
            // IDLE状态缓冲
            idle_state_buf <= IDLE;
            
            // 位计数器缓冲
            bit_counter_buf <= bit_counter;
            
            // 流水线SCL输出缓冲
            scl_out_pipe <= {scl_out_pipe[0], scl_out};
        end
    end
    
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
            // 默认不改变状态
            cmd_ready <= cmd_ready;
            bit_counter <= bit_counter;
            sda_oe <= sda_oe;
            scl_oe <= scl_oe;
            sda_out <= sda_out;
            scl_out <= scl_out;
            
            // IDLE状态处理 - 扁平化条件结构
            if (state == IDLE) begin
                sda_out <= 1'b1;
                scl_out <= 1'b1;
                sda_oe <= 1'b0;
                scl_oe <= 1'b0;
                bit_counter <= 3'h0;
                
                if (cmd_valid && cmd_word_buf[15:12] == 4'h1) begin
                    // 开始传输命令
                    cmd_ready <= 1'b0;
                    addr_buffer <= cmd_word_buf[11:4];
                    data_buffer <= cmd_word_buf[7:0];
                    state <= START;
                end else if (cmd_valid) begin
                    // 未知命令
                    cmd_ready <= 1'b1;
                end else begin
                    cmd_ready <= 1'b1;
                end
            end
            
            // START状态处理
            else if (state == START) begin
                // 发送起始条件
                sda_oe <= 1'b1;
                scl_oe <= 1'b1;
                scl_out <= 1'b1;
                sda_out <= 1'b0; // 发送起始位
                state <= ADDR;
            end
            
            // ADDR状态处理 - 扁平化条件结构
            else if (state == ADDR) begin
                // 发送地址
                sda_oe <= 1'b1;
                scl_oe <= 1'b1;
                scl_out <= !scl_out;
                
                if (scl_out == 1'b0) begin
                    // SCL低电平时设置SDA - 使用位掩码优化
                    sda_out <= (addr_buffer >> (7 - bit_counter_buf)) & 1'b1;
                    
                    if (bit_counter_buf == 3'h7) begin
                        bit_counter <= 3'h0;
                        state <= ACK;
                    end else begin
                        bit_counter <= bit_counter + 1'b1;
                    end
                end
            end
            
            // ACK状态处理 - 扁平化条件结构
            else if (state == ACK) begin
                // 等待ACK
                scl_oe <= 1'b1;
                scl_out <= !scl_out;
                
                if (scl_out == 1'b0) begin
                    // 释放SDA总线以接收ACK
                    sda_oe <= 1'b0;
                    state <= DATA;
                end
            end
            
            // DATA状态处理 - 扁平化条件结构
            else if (state == DATA) begin
                // 发送数据
                sda_oe <= 1'b1;
                scl_oe <= 1'b1;
                scl_out <= !scl_out;
                
                if (scl_out == 1'b0) begin
                    // 优化位访问方式
                    sda_out <= (data_buffer >> (7 - bit_counter_buf)) & 1'b1;
                    
                    if (bit_counter_buf == 3'h7) begin
                        bit_counter <= 3'h0;
                        state <= STOP;
                    end else begin
                        bit_counter <= bit_counter + 1'b1;
                    end
                end
            end
            
            // STOP状态处理
            else if (state == STOP) begin
                // 发送停止条件
                sda_oe <= 1'b1;
                scl_oe <= 1'b1;
                scl_out <= 1'b1;
                sda_out <= 1'b0;
                state <= WAIT;
            end
            
            // WAIT状态处理
            else if (state == WAIT) begin
                // 完成停止条件
                sda_out <= 1'b1;
                state <= idle_state_buf;
                cmd_ready <= 1'b1;
            end
            
            // 默认状态处理
            else begin
                state <= idle_state_buf;
            end
        end
    end
endmodule