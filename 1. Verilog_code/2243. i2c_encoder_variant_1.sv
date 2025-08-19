//SystemVerilog
module i2c_encoder (
    input wire clk,
    input wire start,
    input wire stop,
    input wire [7:0] addr,
    input wire [7:0] data,
    output reg sda,
    output reg scl,
    output wire ack
);
    // FSM状态定义
    localparam IDLE  = 3'd0,
               START = 3'd1,
               ADDR  = 3'd2,
               DATA  = 3'd3,
               STOP  = 3'd4;
    
    // 主控制寄存器
    reg [2:0] state_r, state_next;
    reg [3:0] bit_cnt_r, bit_cnt_next;
    reg ack_r, ack_next;
    
    // 数据路径寄存器
    reg [7:0] addr_r, data_r;
    reg sda_next, scl_next;
    reg scl_toggle;
    
    // 合并所有posedge clk触发的always块
    always @(posedge clk) begin
        // 控制路径状态寄存器更新
        state_r <= state_next;
        bit_cnt_r <= bit_cnt_next;
        ack_r <= ack_next;
        sda <= sda_next;
        scl <= scl_next;
        
        // 数据路径寄存器更新 - 在开始传输时捕获输入数据
        if (state_r == IDLE && start) begin
            addr_r <= addr;
            data_r <= data;
        end
    end
    
    // 下一状态和控制信号生成
    always @(*) begin
        // 默认保持当前值
        state_next = state_r;
        bit_cnt_next = bit_cnt_r;
        ack_next = ack_r;
        sda_next = sda;
        scl_next = scl;
        scl_toggle = 1'b0;
        
        case(state_r)
            IDLE: begin
                scl_next = 1'b1;
                sda_next = 1'b1;
                bit_cnt_next = 4'h0;
                ack_next = 1'b0;
                
                if (start) begin
                    state_next = START;
                end
            end
            
            START: begin
                scl_next = 1'b0;
                sda_next = 1'b0;
                state_next = ADDR;
            end
            
            ADDR: begin
                if (bit_cnt_r < 8) begin
                    sda_next = addr_r[7 - bit_cnt_r];
                    scl_toggle = 1'b1;
                    bit_cnt_next = bit_cnt_r + 1'b1;
                end else begin
                    state_next = DATA;
                    bit_cnt_next = 4'h0;
                    ack_next = 1'b1; // 地址已发送标志
                    scl_next = 1'b0; // 准备下一阶段
                    sda_next = 1'b0; // 准备数据发送
                end
            end
            
            DATA: begin
                if (bit_cnt_r < 8) begin
                    sda_next = data_r[7 - bit_cnt_r];
                    scl_toggle = 1'b1;
                    bit_cnt_next = bit_cnt_r + 1'b1;
                end else if (stop) begin
                    state_next = STOP;
                    ack_next = 1'b1; // 数据已发送标志
                    sda_next = 1'b0; // 准备STOP条件
                    scl_next = 1'b0;
                end else begin
                    bit_cnt_next = 4'h0; // 准备下一个数据字节
                    ack_next = 1'b1;
                    // 可以在此处添加逻辑以处理多字节传输
                end
            end
            
            STOP: begin
                scl_next = 1'b1;
                sda_next = 1'b1;
                state_next = IDLE;
            end
            
            default: begin
                state_next = IDLE;
                scl_next = 1'b1;
                sda_next = 1'b1;
            end
        endcase
        
        // SCL时钟生成 - 在ADDR和DATA状态下
        if (scl_toggle) begin
            scl_next = ~scl;
        end
    end
    
    // ACK输出信号连接
    assign ack = ack_r;
    
endmodule