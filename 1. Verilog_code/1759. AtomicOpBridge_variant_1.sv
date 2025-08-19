//SystemVerilog
module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:ADD,1:AND,2:OR,3:XOR
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] reg_data
);

    wire [DATA_W-1:0] alu_result;

    // 实例化算术逻辑单元
    ALU #(.DATA_W(DATA_W)) alu_inst (
        .op_type(op_type),
        .reg_data(reg_data),
        .operand(operand),
        .result(alu_result)
    );

    // 时序逻辑更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reg_data <= {DATA_W{1'b0}};
        else 
            reg_data <= alu_result;
    end
endmodule

// 算术逻辑单元模块
module ALU #(
    parameter DATA_W = 32
)(
    input [1:0] op_type,
    input [DATA_W-1:0] reg_data,
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] result
);

    // 组合逻辑计算
    always @(*) begin
        case(op_type)
            2'b00: result = reg_data + operand; // ADD
            2'b01: result = reg_data & operand; // AND
            2'b10: result = reg_data | operand; // OR
            2'b11: result = reg_data ^ operand; // XOR
            default: result = reg_data;
        endcase
    end
endmodule