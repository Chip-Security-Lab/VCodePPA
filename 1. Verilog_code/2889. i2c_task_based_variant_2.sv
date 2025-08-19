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
    // 优化状态编码，使用独热码以提高电路效率
    localparam IDLE  = 7'b0000001;
    localparam START = 7'b0000010;
    localparam ADDR  = 7'b0000100;
    localparam DATA  = 7'b0001000;
    localparam ACK   = 7'b0010000;
    localparam STOP  = 7'b0100000;
    localparam WAIT  = 7'b1000000;
    
    reg [6:0] state;
    reg [7:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [2:0] bit_counter;
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // I2C总线驱动
    assign sda = sda_oe ? 1'b0 : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
    
    // 命令类型解码 - 预解码以减少比较链
    wire is_start_cmd = cmd_word[15:12] == 4'h1;
    
    // 位检测逻辑优化
    wire is_last_bit = (bit_counter == 3'h7);
    
    // 状态机实现，优化比较逻辑
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
                        if (is_start_cmd) begin
                            // 优化：直接使用预解码的结果
                            addr_buffer <= cmd_word[11:4];
                            data_buffer <= cmd_word[7:0];
                            state <= START;
                        end else begin
                            cmd_ready <= 1'b1; // 未知命令
                        end
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
                    
                    // 时钟控制 - 使用if-else替代条件运算符
                    if (scl_out == 1'b1) begin
                        scl_out <= 1'b0;
                    end else begin
                        scl_out <= 1'b1;
                    end
                    
                    if (scl_out == 1'b0) begin
                        // 优化：使用移位寄存器逻辑减少多路复用器资源
                        sda_out <= addr_buffer[7];
                        addr_buffer <= {addr_buffer[6:0], 1'b0};
                        
                        // 使用预计算的条件优化
                        if (is_last_bit) begin
                            bit_counter <= 3'h0;
                            state <= ACK;
                        end else begin
                            bit_counter <= bit_counter + 3'h1;
                        end
                    end
                end
                
                ACK: begin
                    // 等待ACK
                    scl_oe <= 1'b1;
                    
                    // 时钟控制 - 使用if-else替代条件运算符
                    if (scl_out == 1'b1) begin
                        scl_out <= 1'b0;
                    end else begin
                        scl_out <= 1'b1;
                    end
                    
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
                    
                    // 时钟控制 - 使用if-else替代条件运算符
                    if (scl_out == 1'b1) begin
                        scl_out <= 1'b0;
                    end else begin
                        scl_out <= 1'b1;
                    end
                    
                    if (scl_out == 1'b0) begin
                        // 优化：使用移位寄存器逻辑减少多路复用器资源
                        sda_out <= data_buffer[7];
                        data_buffer <= {data_buffer[6:0], 1'b0};
                        
                        // 使用预计算的条件优化
                        if (is_last_bit) begin
                            bit_counter <= 3'h0;
                            state <= STOP;
                        end else begin
                            bit_counter <= bit_counter + 3'h1;
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