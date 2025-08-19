//SystemVerilog
//IEEE 1364-2005 Verilog
module usb_token_encoder #(parameter ADDR_WIDTH = 7, PID_WIDTH = 4) (
    input wire clk, rst_n,
    input wire [PID_WIDTH-1:0] pid,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [3:0] endp,
    input wire encode_en,
    input wire ready_next,  // 下级模块是否就绪接收数据
    output reg [15:0] token_packet,
    output reg packet_ready,
    output reg valid_out     // 输出有效信号
);
    // 时钟缓冲信号 - 扇出缓冲
    (* dont_touch = "true" *) reg clk_buf1, clk_buf2, clk_buf3;
    
    // 流水线阶段寄存器和状态信号
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [3:0] endp_stage1;
    reg valid_stage1;
    
    // ready_next信号的缓冲寄存器
    (* dont_touch = "true" *) reg ready_next_buf1, ready_next_buf2, ready_next_buf3;
    
    // addr_stage1和endp_stage1的缓冲寄存器
    (* dont_touch = "true" *) reg [ADDR_WIDTH-1:0] addr_stage1_buf1, addr_stage1_buf2;
    (* dont_touch = "true" *) reg [3:0] endp_stage1_buf1, endp_stage1_buf2;
    
    // 中间计算结果寄存器
    reg [4:0] crc5_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [3:0] endp_stage2;
    reg valid_stage2;
    
    // crc5_stage2的缓冲寄存器
    (* dont_touch = "true" *) reg [4:0] crc5_stage2_buf1, crc5_stage2_buf2;
    
    // 时钟缓冲逻辑
    always @(posedge clk) begin
        clk_buf1 <= 1'b1;
        clk_buf2 <= clk_buf1;
        clk_buf3 <= clk_buf2;
    end
    
    // ready_next缓冲逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_next_buf1 <= 1'b0;
            ready_next_buf2 <= 1'b0;
            ready_next_buf3 <= 1'b0;
        end else begin
            ready_next_buf1 <= ready_next;
            ready_next_buf2 <= ready_next_buf1;
            ready_next_buf3 <= ready_next_buf2;
        end
    end
    
    // 第一级流水线 - 输入缓存和数据准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            endp_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            if (encode_en && (ready_next_buf1 || !valid_out)) begin
                addr_stage1 <= addr;
                endp_stage1 <= endp;
                valid_stage1 <= 1'b1;
            end else if (ready_next_buf1) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // addr_stage1和endp_stage1的缓冲逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1_buf1 <= 0;
            addr_stage1_buf2 <= 0;
            endp_stage1_buf1 <= 0;
            endp_stage1_buf2 <= 0;
        end else begin
            addr_stage1_buf1 <= addr_stage1;
            addr_stage1_buf2 <= addr_stage1_buf1;
            endp_stage1_buf1 <= endp_stage1;
            endp_stage1_buf2 <= endp_stage1_buf1;
        end
    end
    
    // 第二级流水线 - CRC5计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc5_stage2 <= 5'b0;
            addr_stage2 <= 0;
            endp_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && (ready_next_buf2 || !valid_out)) begin
            // CRC5计算 - 使用缓冲后的信号
            crc5_stage2[0] <= ^{endp_stage1_buf1[3:0]};
            crc5_stage2[1] <= ^{addr_stage1_buf1[0], endp_stage1_buf1[3], endp_stage1_buf1[1:0]};
            crc5_stage2[2] <= ^{addr_stage1_buf1[2:0], endp_stage1_buf1[2:1]};
            crc5_stage2[3] <= ^{addr_stage1_buf1[4:0], endp_stage1_buf1[3:0]};
            crc5_stage2[4] <= ^{addr_stage1_buf1[6:0], endp_stage1_buf1[3:0]};
            
            // 传递数据
            addr_stage2 <= addr_stage1_buf2;
            endp_stage2 <= endp_stage1_buf2;
            valid_stage2 <= valid_stage1;
        end else if (ready_next_buf2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // crc5_stage2的缓冲逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc5_stage2_buf1 <= 5'b0;
            crc5_stage2_buf2 <= 5'b0;
        end else begin
            crc5_stage2_buf1 <= crc5_stage2;
            crc5_stage2_buf2 <= crc5_stage2_buf1;
        end
    end
    
    // 第三级流水线 - 输出组装
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_packet <= 16'h0000;
            packet_ready <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_stage2 && (ready_next_buf3 || !valid_out)) begin
            // 组装最终输出 - 使用缓冲后的CRC5
            token_packet <= {crc5_stage2_buf1, endp_stage2, addr_stage2};
            packet_ready <= 1'b1;
            valid_out <= 1'b1;
        end else if (ready_next_buf3 && valid_out) begin
            // 当下一级准备好接收新数据时清除有效标志
            valid_out <= 1'b0;
            packet_ready <= 1'b0;
        end
    end
endmodule