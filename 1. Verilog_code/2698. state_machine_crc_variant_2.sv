//SystemVerilog
module state_machine_crc(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output reg [15:0] crc_out,
    output reg crc_ready
);
    // 流水线常量定义
    localparam [15:0] POLY = 16'h1021;
    localparam [1:0] IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // 流水线阶段寄存器
    reg [1:0] state_stage1, state_stage2;
    reg [2:0] bit_count_stage1;
    reg [15:0] crc_calc_stage1, crc_calc_stage2;
    reg crc_valid_stage1, crc_valid_stage2;
    reg [7:0] data_stage1;
    
    // 流水线计算信号
    wire crc_feedback_stage1;
    wire [15:0] crc_next_stage1;
    
    // 第一级流水线反馈计算
    assign crc_feedback_stage1 = crc_calc_stage1[15] ^ data_stage1[bit_count_stage1];
    assign crc_next_stage1 = {crc_calc_stage1[14:0], 1'b0} ^ (crc_feedback_stage1 ? POLY : 16'h0);
    
    // 流水线第一级 - 输入处理和计算
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= IDLE;
            crc_calc_stage1 <= 16'hFFFF;
            bit_count_stage1 <= 3'd0;
            crc_valid_stage1 <= 1'b0;
            data_stage1 <= 8'd0;
        end else begin
            case (state_stage1)
                IDLE: begin
                    if (start) begin
                        state_stage1 <= PROCESS;
                        bit_count_stage1 <= 3'd0;
                        crc_valid_stage1 <= 1'b1;
                        data_stage1 <= data;
                    end else begin
                        crc_valid_stage1 <= 1'b0;
                    end
                end
                
                PROCESS: begin
                    crc_calc_stage1 <= crc_next_stage1;
                    
                    if (bit_count_stage1 == 3'b111) begin
                        state_stage1 <= FINALIZE;
                    end else begin
                        bit_count_stage1 <= bit_count_stage1 + 3'd1;
                    end
                end
                
                FINALIZE: begin
                    state_stage1 <= IDLE;
                    crc_valid_stage1 <= 1'b0;
                end
                
                default: state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 流水线第二级 - 结果整理
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= IDLE;
            crc_calc_stage2 <= 16'hFFFF;
            crc_valid_stage2 <= 1'b0;
            crc_out <= 16'hFFFF;
            crc_ready <= 1'b0;
        end else begin
            // 传递状态到第二级
            state_stage2 <= state_stage1;
            crc_calc_stage2 <= crc_calc_stage1;
            crc_valid_stage2 <= crc_valid_stage1;
            
            // 输出逻辑
            if (state_stage2 == FINALIZE && crc_valid_stage2) begin
                crc_out <= crc_calc_stage2;
                crc_ready <= 1'b1;
            end else begin
                crc_ready <= 1'b0;
            end
        end
    end
endmodule