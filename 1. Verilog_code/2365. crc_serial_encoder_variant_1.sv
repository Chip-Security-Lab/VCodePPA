//SystemVerilog
module crc_serial_encoder #(parameter DW=16)(
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg serial_out
);
    // 流水线阶段寄存器
    reg [4:0] crc_reg_stage1;
    reg [4:0] crc_reg_stage2;
    reg [DW+4:0] shift_reg_stage1;
    reg [DW+4:0] shift_reg_stage2;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    
    // 中间计算结果 - 优化了比较逻辑
    wire [4:0] crc_next;
    wire [4:0] crc_xor = shift_reg_stage1[DW+4:DW]; 
    
    // 优化的CRC计算 - 使用位异或操作
    assign crc_next = crc_reg_stage1 ^ crc_xor;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 使用非阻塞赋值重置所有寄存器
            shift_reg_stage1 <= {(DW+5){1'b0}};
            crc_reg_stage1 <= 5'h1F;
            valid_stage1 <= 1'b0;
            
            shift_reg_stage2 <= {(DW+5){1'b0}};
            crc_reg_stage2 <= 5'h1F;
            valid_stage2 <= 1'b0;
            
            serial_out <= 1'b0;
        end 
        else begin
            // 第一流水线阶段 - 优化条件结构
            valid_stage1 <= en ? 1'b1 : valid_stage1;
            
            if (en) begin
                shift_reg_stage1 <= {data_in, crc_reg_stage1};
                crc_reg_stage1 <= crc_next;
            end
            else if (valid_stage1) begin
                shift_reg_stage1 <= {shift_reg_stage1[DW+4-1:0], 1'b0};
            end
            
            // 第二流水线阶段 - 优化数据传输逻辑
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                shift_reg_stage2 <= shift_reg_stage1;
                crc_reg_stage2 <= crc_reg_stage1;
            end
            else if (valid_stage2) begin
                shift_reg_stage2 <= {shift_reg_stage2[DW+4-1:0], 1'b0};
                serial_out <= shift_reg_stage2[DW+4];
            end
            else begin
                serial_out <= 1'b0;
            end
        end
    end
endmodule