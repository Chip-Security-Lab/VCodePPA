//SystemVerilog
module usb_token_encoder #(parameter ADDR_WIDTH = 7, PID_WIDTH = 4) (
    input wire clk, rst_n,
    input wire [PID_WIDTH-1:0] pid,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [3:0] endp,
    input wire encode_en,
    output reg [15:0] token_packet,
    output reg packet_ready
);
    // 内部流水线寄存器
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    reg [3:0] endp_stage1, endp_stage2;
    reg encode_en_stage1, encode_en_stage2, encode_en_stage3;
    reg [PID_WIDTH-1:0] pid_stage1, pid_stage2, pid_stage3;
    
    // CRC5中间计算寄存器
    reg [4:0] crc5_partial_stage1;
    reg [4:0] crc5_stage2;
    
    // 状态寄存器
    localparam IDLE = 1'b0;
    localparam ENCODE = 1'b1;
    reg state_stage2, state_stage3;
    
    // 第1级流水线：寄存输入并开始CRC5部分计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            endp_stage1 <= 4'b0000;
            encode_en_stage1 <= 1'b0;
            pid_stage1 <= {PID_WIDTH{1'b0}};
            crc5_partial_stage1 <= 5'b00000;
        end
        else begin
            addr_stage1 <= addr;
            endp_stage1 <= endp;
            encode_en_stage1 <= encode_en;
            pid_stage1 <= pid;
            
            // 第一阶段CRC5部分计算
            crc5_partial_stage1[0] <= ^{endp[3:0]};
            crc5_partial_stage1[1] <= ^{addr[0], endp[3], endp[1:0]};
            crc5_partial_stage1[2] <= ^{addr[2:0], endp[2:1]};
            crc5_partial_stage1[3] <= ^{addr[4:0], endp[3:0]};
            crc5_partial_stage1[4] <= ^{addr[6:0], endp[3:0]};
        end
    end
    
    // 第2级流水线：完成CRC5计算，开始状态控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {ADDR_WIDTH{1'b0}};
            endp_stage2 <= 4'b0000;
            encode_en_stage2 <= 1'b0;
            pid_stage2 <= {PID_WIDTH{1'b0}};
            crc5_stage2 <= 5'b00000;
            state_stage2 <= IDLE;
        end
        else begin
            addr_stage2 <= addr_stage1;
            endp_stage2 <= endp_stage1;
            encode_en_stage2 <= encode_en_stage1;
            pid_stage2 <= pid_stage1;
            
            // 将CRC5计算结果传到第二级
            crc5_stage2 <= crc5_partial_stage1;
            
            // 状态更新逻辑 - 第一部分
            case (state_stage2)
                IDLE: begin
                    if (encode_en_stage1)
                        state_stage2 <= ENCODE;
                end
                
                ENCODE: begin
                    if (!encode_en_stage1)
                        state_stage2 <= IDLE;
                end
                
                default: state_stage2 <= IDLE;
            endcase
        end
    end
    
    // 第3级流水线：完成状态控制和输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_packet <= 16'h0000;
            packet_ready <= 1'b0;
            encode_en_stage3 <= 1'b0;
            pid_stage3 <= {PID_WIDTH{1'b0}};
            state_stage3 <= IDLE;
        end
        else begin
            encode_en_stage3 <= encode_en_stage2;
            pid_stage3 <= pid_stage2;
            state_stage3 <= state_stage2;
            
            // 状态更新逻辑 - 第二部分，输出控制
            case (state_stage2)
                IDLE: begin
                    if (encode_en_stage2) begin
                        token_packet <= {crc5_stage2, endp_stage2, addr_stage2};
                        packet_ready <= 1'b1;
                    end
                end
                
                ENCODE: begin
                    if (!encode_en_stage2) begin
                        packet_ready <= 1'b0;
                    end
                end
                
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule