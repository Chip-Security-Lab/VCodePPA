//SystemVerilog
module i2c_encoder (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire stop,
    input wire [7:0] addr,
    input wire [7:0] data,
    input wire ready_in,
    output reg sda,
    output reg scl,
    output wire ack,
    output wire valid_out,
    output wire ready_out
);
    // 参数定义 - 使用更有效的状态编码
    localparam IDLE = 3'd0, START = 3'd1, ADDR = 3'd2, DATA = 3'd3, STOP = 3'd4;
    
    // 流水线阶段寄存器
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [3:0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
    reg [7:0] addr_stage1, addr_stage2;
    reg [7:0] data_stage1, data_stage2, data_stage3;
    reg start_stage1, start_stage2, start_stage3;
    reg stop_stage1, stop_stage2, stop_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    reg ack_stage1, ack_stage2, ack_stage3;
    
    // 临时信号
    reg sda_stage1, sda_stage2, sda_stage3;
    reg scl_stage1, scl_stage2, scl_stage3;
    
    // 流水线控制逻辑 - 优化布尔表达式
    assign ready_out = (state_stage1 == IDLE) | ~valid_stage1;
    assign valid_out = valid_stage3 & (state_stage3 == STOP);
    assign ack = ack_stage3;
    
    // 优化第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            bit_cnt_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            start_stage1 <= 1'b0;
            stop_stage1 <= 1'b0;
            addr_stage1 <= 8'h0;
            data_stage1 <= 8'h0;
            ack_stage1 <= 1'b0;
            sda_stage1 <= 1'b1;
            scl_stage1 <= 1'b1;
        end else begin
            // 默认保持值，减少不必要的条件判断
            
            // 接收新的请求 - 优化逻辑
            if (ready_out & ready_in) begin
                addr_stage1 <= addr;
                data_stage1 <= data;
                start_stage1 <= start;
                stop_stage1 <= stop;
                valid_stage1 <= 1'b1;
                
                if (start) begin
                    state_stage1 <= START;
                    bit_cnt_stage1 <= 4'h0;
                    ack_stage1 <= 1'b0;
                    sda_stage1 <= 1'b0;
                    scl_stage1 <= 1'b0;
                end
            end else if (valid_stage1) begin
                // 使用优化的状态转换逻辑
                case (state_stage1)
                    IDLE: begin
                        scl_stage1 <= 1'b1;
                        sda_stage1 <= 1'b1;
                        if (start_stage1)
                            state_stage1 <= START;
                    end
                    
                    START: begin
                        scl_stage1 <= 1'b0;
                        sda_stage1 <= 1'b0;
                        state_stage1 <= ADDR;
                    end
                    
                    ADDR: begin
                        // 优化比较操作，使用单一范围检查
                        if (bit_cnt_stage1 < 4'h8) begin
                            sda_stage1 <= addr_stage1[7 - bit_cnt_stage1];
                            bit_cnt_stage1 <= bit_cnt_stage1 + 4'h1;
                            scl_stage1 <= ~scl_stage1;
                        end else begin
                            state_stage1 <= DATA;
                            bit_cnt_stage1 <= 4'h0;
                            ack_stage1 <= 1'b1;
                        end
                    end
                    
                    DATA: begin
                        // 优化比较链
                        if (bit_cnt_stage1 < 4'h8) begin
                            sda_stage1 <= data_stage1[7 - bit_cnt_stage1];
                            bit_cnt_stage1 <= bit_cnt_stage1 + 4'h1;
                            scl_stage1 <= ~scl_stage1;
                        end else if (stop_stage1) begin
                            state_stage1 <= STOP;
                            ack_stage1 <= 1'b1;
                        end else begin
                            bit_cnt_stage1 <= 4'h0;
                            ack_stage1 <= 1'b1;
                        end
                    end
                    
                    STOP: begin
                        scl_stage1 <= 1'b1;
                        sda_stage1 <= 1'b1;
                        state_stage1 <= IDLE;
                        valid_stage1 <= 1'b0; // 操作完成
                    end
                    
                    default: state_stage1 <= IDLE;
                endcase
            end
        end
    end
    
    // 优化第二级流水线 - 改进寄存器传输
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {state_stage2, bit_cnt_stage2, valid_stage2} <= {IDLE, 4'h0, 1'b0};
            {addr_stage2, data_stage2} <= {8'h0, 8'h0};
            {start_stage2, stop_stage2, ack_stage2} <= 3'b000;
            {sda_stage2, scl_stage2} <= 2'b11;
        end else begin
            // 批量信号传递，减少路径延迟
            {state_stage2, bit_cnt_stage2, valid_stage2} <= {state_stage1, bit_cnt_stage1, valid_stage1};
            {addr_stage2, data_stage2} <= {addr_stage1, data_stage1};
            {start_stage2, stop_stage2, ack_stage2} <= {start_stage1, stop_stage1, ack_stage1};
            {sda_stage2, scl_stage2} <= {sda_stage1, scl_stage1};
        end
    end
    
    // 优化第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {state_stage3, bit_cnt_stage3, valid_stage3} <= {IDLE, 4'h0, 1'b0};
            data_stage3 <= 8'h0;
            {start_stage3, stop_stage3, ack_stage3} <= 3'b000;
            {sda, scl} <= 2'b11;
        end else begin
            // 批量信号传递，减少门级数
            {state_stage3, bit_cnt_stage3, valid_stage3} <= {state_stage2, bit_cnt_stage2, valid_stage2};
            data_stage3 <= data_stage2;
            {start_stage3, stop_stage3, ack_stage3} <= {start_stage2, stop_stage2, ack_stage2};
            
            // 直接输出赋值
            {sda, scl} <= {sda_stage2, scl_stage2};
        end
    end
    
endmodule