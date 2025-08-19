//SystemVerilog
module midi_encoder (
    input wire clk,
    input wire rst_n,
    input wire note_on,
    input wire [6:0] note,
    input wire [6:0] velocity,
    
    // 流水线控制信号
    input wire ready_in,
    output reg valid_out,
    
    // 数据输出
    output reg [7:0] tx_byte
);
    
    // 流水线阶段状态和控制信号
    reg [1:0] state;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线数据寄存器
    reg [7:0] tx_byte_stage1, tx_byte_stage2, tx_byte_stage3;
    reg [6:0] note_stage1, note_stage2;
    reg [6:0] velocity_stage1;
    
    // 第一级流水线 - 命令检测和准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            tx_byte_stage1 <= 8'h00;
            note_stage1 <= 7'h00;
            velocity_stage1 <= 7'h00;
        end else if (ready_in) begin
            valid_stage1 <= note_on;
            tx_byte_stage1 <= 8'h90; // Note On 命令
            note_stage1 <= note;
            velocity_stage1 <= velocity;
        end
    end
    
    // 第二级流水线 - 准备音符数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            tx_byte_stage2 <= 8'h00;
            note_stage2 <= 7'h00;
        end else begin
            valid_stage2 <= valid_stage1;
            tx_byte_stage2 <= tx_byte_stage1;
            note_stage2 <= note_stage1;
        end
    end
    
    // 第三级流水线 - 准备力度数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            tx_byte_stage3 <= 8'h00;
        end else begin
            valid_stage3 <= valid_stage2;
            tx_byte_stage3 <= {1'b0, note_stage2};
        end
    end
    
    // 状态机控制和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'b00;
            valid_out <= 1'b0;
            tx_byte <= 8'h00;
        end else begin
            case (state)
                2'b00: begin
                    if (valid_stage1) begin
                        tx_byte <= tx_byte_stage1;  // 命令字节 (0x90)
                        valid_out <= 1'b1;
                        state <= 2'b01;
                    end else begin
                        valid_out <= 1'b0;
                    end
                end
                
                2'b01: begin
                    if (valid_stage2) begin
                        tx_byte <= {1'b0, note_stage2};  // 音符字节
                        valid_out <= 1'b1;
                        state <= 2'b10;
                    end else begin
                        valid_out <= 1'b0;
                        state <= 2'b00;
                    end
                end
                
                2'b10: begin
                    if (valid_stage3) begin
                        tx_byte <= {1'b0, velocity_stage1};  // 力度字节
                        valid_out <= 1'b1;
                        state <= 2'b00;
                    end else begin
                        valid_out <= 1'b0;
                        state <= 2'b00;
                    end
                end
                
                default: begin
                    state <= 2'b00;
                    valid_out <= 1'b0;
                end
            endcase
        end
    end
    
endmodule