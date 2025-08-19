//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module decoder_sync_reg (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [3:0] addr,
    output reg [15:0] decoded,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out,
    input wire flush
);
    // 流水线第一级：地址寄存和使能控制
    reg [3:0] addr_stage1;
    reg en_stage1;
    reg valid_stage1;
    
    // 流水线第二级：解码计算中间结果
    reg [15:0] decoded_stage2;
    reg valid_stage2;
    
    // 第一级流水线：寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            case ({flush, 1'b1})
                2'b10, 2'b11: valid_stage1 <= 1'b0;
                2'b01: begin
                    addr_stage1 <= addr;
                    en_stage1 <= en;
                    valid_stage1 <= valid_in;
                end
                default: valid_stage1 <= valid_stage1;
            endcase
        end
    end
    
    // 第二级流水线：执行解码计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
        end
        else begin
            case ({flush, valid_stage1})
                2'b10, 2'b11: valid_stage2 <= 1'b0;
                2'b01: begin
                    decoded_stage2 <= en_stage1 ? (1'b1 << addr_stage1) : decoded_stage2;
                    valid_stage2 <= 1'b1;
                end
                default: valid_stage2 <= valid_stage2;
            endcase
        end
    end
    
    // 输出级：传递最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 16'h0;
            valid_out <= 1'b0;
        end
        else begin
            case ({flush, valid_stage2})
                2'b10, 2'b11: valid_out <= 1'b0;
                2'b01: begin
                    decoded <= decoded_stage2;
                    valid_out <= 1'b1;
                end
                default: valid_out <= valid_out;
            endcase
        end
    end
endmodule