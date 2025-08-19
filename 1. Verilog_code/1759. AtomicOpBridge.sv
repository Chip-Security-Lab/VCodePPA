module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:ADD,1:AND,2:OR,3:XOR
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] reg_data
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reg_data <= 0;
        else 
            case(op_type)
                2'b00: reg_data <= reg_data + operand;
                2'b01: reg_data <= reg_data & operand;
                2'b10: reg_data <= reg_data | operand;
                2'b11: reg_data <= reg_data ^ operand;
                default: reg_data <= reg_data; // 默认情况
            endcase
    end
endmodule