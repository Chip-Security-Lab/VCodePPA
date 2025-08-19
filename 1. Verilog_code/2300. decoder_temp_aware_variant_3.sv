//SystemVerilog
module decoder_temp_aware #(parameter THRESHOLD=85) (
    input clk,
    input [7:0] temp,
    input [3:0] addr,
    output reg [15:0] decoded
);
    reg [15:0] barrel_shifter_out;
    
    // 桶形移位器实现
    always @(*) begin
        case(addr)
            4'd0:  barrel_shifter_out = 16'h0001;
            4'd1:  barrel_shifter_out = 16'h0002;
            4'd2:  barrel_shifter_out = 16'h0004;
            4'd3:  barrel_shifter_out = 16'h0008;
            4'd4:  barrel_shifter_out = 16'h0010;
            4'd5:  barrel_shifter_out = 16'h0020;
            4'd6:  barrel_shifter_out = 16'h0040;
            4'd7:  barrel_shifter_out = 16'h0080;
            4'd8:  barrel_shifter_out = 16'h0100;
            4'd9:  barrel_shifter_out = 16'h0200;
            4'd10: barrel_shifter_out = 16'h0400;
            4'd11: barrel_shifter_out = 16'h0800;
            4'd12: barrel_shifter_out = 16'h1000;
            4'd13: barrel_shifter_out = 16'h2000;
            4'd14: barrel_shifter_out = 16'h4000;
            4'd15: barrel_shifter_out = 16'h8000;
            default: barrel_shifter_out = 16'h0000;
        endcase
    end
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        decoded <= (temp > THRESHOLD) ? (barrel_shifter_out & 16'h00FF) : barrel_shifter_out;
    end
endmodule