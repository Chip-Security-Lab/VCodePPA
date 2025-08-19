//SystemVerilog
module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:ADD, 1:AND, 2:OR, 3:XOR
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] reg_data
);

    always @(*) begin
        case(op_type)
            2'b00: reg_data = reg_data + operand; // 加法操作
            2'b01: reg_data = reg_data & operand; // 与操作
            2'b10: reg_data = reg_data | operand; // 或操作
            2'b11: reg_data = reg_data ^ operand; // 异或操作
            default: reg_data = reg_data; // 保持原值
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reg_data <= 0;
    end
endmodule