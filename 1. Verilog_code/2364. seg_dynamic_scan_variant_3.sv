//SystemVerilog
module seg_dynamic_scan #(parameter N=4)(
    input clk,
    input [N*8-1:0] seg_data,
    output reg [3:0] sel,
    output [7:0] seg
);
    reg [1:0] cnt;
    reg [7:0] seg_reg;
    
    // 桶形移位器实现变量移位
    always @(*) begin
        case(cnt)
            2'b00: seg_reg = seg_data[7:0];
            2'b01: seg_reg = seg_data[15:8];
            2'b10: seg_reg = seg_data[23:16];
            2'b11: seg_reg = seg_data[31:24];
            default: seg_reg = 8'b0;
        endcase
    end
    
    assign seg = seg_reg;
    
    // 桶形移位器实现sel信号生成
    always @(posedge clk) begin
        cnt <= cnt + 1;
        
        case(cnt)
            2'b00: sel <= 4'b1110;
            2'b01: sel <= 4'b1101;
            2'b10: sel <= 4'b1011;
            2'b11: sel <= 4'b0111;
            default: sel <= 4'b1111;
        endcase
    end
endmodule