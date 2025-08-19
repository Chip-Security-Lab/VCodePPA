//SystemVerilog
module seg_dynamic_scan #(parameter N=4)(
    input clk,
    input [N*8-1:0] seg_data,
    output reg [3:0] sel,
    output [7:0] seg
);
    reg [1:0] cnt;
    
    // 使用桶形移位器结构实现变量位选择
    reg [7:0] seg_mux;
    always @(*) begin
        case(cnt)
            2'b00: seg_mux = seg_data[7:0];
            2'b01: seg_mux = seg_data[15:8];
            2'b10: seg_mux = seg_data[23:16];
            2'b11: seg_mux = seg_data[31:24];
            default: seg_mux = 8'h00;
        endcase
    end
    
    assign seg = seg_mux;
    
    // 使用桶形移位器结构实现位移操作
    reg [3:0] sel_barrel;
    always @(*) begin
        case(cnt)
            2'b00: sel_barrel = 4'b1110;
            2'b01: sel_barrel = 4'b1101;
            2'b10: sel_barrel = 4'b1011;
            2'b11: sel_barrel = 4'b0111;
            default: sel_barrel = 4'b1111;
        endcase
    end
    
    always @(posedge clk) begin
        cnt <= cnt + 1;
        sel <= sel_barrel;
    end
endmodule