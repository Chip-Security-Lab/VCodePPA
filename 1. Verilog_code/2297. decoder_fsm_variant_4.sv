//SystemVerilog
module decoder_fsm (
    input clk, rst_n,
    input [3:0] addr,
    output reg [7:0] decoded
);
    // 使用二进制编码表示状态
    // 使用3位二进制可以表示5个状态（需要至少3位）
    parameter [2:0] 
        IDLE    = 3'b000,
        DECODE1 = 3'b001, 
        DECODE2 = 3'b010, 
        DECODE3 = 3'b011, 
        HOLD    = 3'b100;
    
    reg [2:0] curr_state;
    reg [3:0] addr_stage1, addr_stage2;
    reg [7:0] decode_temp1, decode_temp2;
    reg decode_valid_stage1, decode_valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            decoded <= 8'h00;
            addr_stage1 <= 4'h0;
            addr_stage2 <= 4'h0;
            decode_temp1 <= 8'h00;
            decode_temp2 <= 8'h00;
            decode_valid_stage1 <= 1'b0;
            decode_valid_stage2 <= 1'b0;
        end else begin
            case(curr_state)
                IDLE: begin
                    if (addr != 0) begin
                        curr_state <= DECODE1;
                        addr_stage1 <= addr;
                    end
                end
                
                DECODE1: begin
                    // 第一阶段解码 - 地址有效性检查
                    curr_state <= DECODE2;
                    decode_valid_stage1 <= (addr_stage1 < 8);
                    addr_stage2 <= addr_stage1;
                end
                
                DECODE2: begin
                    // 第二阶段解码 - 计算初步移位量
                    curr_state <= DECODE3;
                    decode_valid_stage2 <= decode_valid_stage1;
                    if (decode_valid_stage1)
                        decode_temp1 <= (8'h01 << addr_stage2[1:0]);
                    else
                        decode_temp1 <= 8'h00;
                end
                
                DECODE3: begin
                    // 第三阶段解码 - 完成最终移位计算
                    curr_state <= HOLD;
                    if (decode_valid_stage2) begin
                        if (addr_stage2[3:2] == 2'b00)
                            decode_temp2 <= decode_temp1;
                        else if (addr_stage2[3:2] == 2'b01)
                            decode_temp2 <= {decode_temp1[3:0], 4'h0};
                        else
                            decode_temp2 <= 8'h00;
                    end else
                        decode_temp2 <= 8'h00;
                end
                
                HOLD: begin
                    curr_state <= IDLE;
                    decoded <= decode_temp2;
                end
                
                default: curr_state <= IDLE;
            endcase
        end
    end
endmodule