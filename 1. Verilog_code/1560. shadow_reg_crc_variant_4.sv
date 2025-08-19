//SystemVerilog
module shadow_reg_crc #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW+3:0] reg_out  // [DW+3:DW]为CRC
);
    wire [3:0] crc = data_in[3:0] ^ data_in[7:4];
    
    // 使用组合控制信号作为case条件
    reg [1:0] ctrl;
    always @(*) begin
        ctrl = {rst, en};
    end
    
    always @(posedge clk) begin
        case(ctrl)
            2'b10, 2'b11: reg_out <= 0;          // rst优先级最高
            2'b01:        reg_out <= {crc, data_in};  // en有效
            2'b00:        reg_out <= reg_out;    // 保持状态
        endcase
    end
endmodule