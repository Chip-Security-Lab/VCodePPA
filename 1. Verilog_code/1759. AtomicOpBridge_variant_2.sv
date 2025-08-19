//SystemVerilog
module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:ADD,1:AND,2:OR,3:XOR
    input [DATA_W-1:0] operand,
    input valid_in,
    output valid_out,
    output reg [DATA_W-1:0] reg_data
);
    // Pipeline stage registers
    reg [1:0] op_type_stage1;
    reg [DATA_W-1:0] operand_stage1;
    reg [DATA_W-1:0] reg_data_stage1;
    reg valid_stage1;
    
    // Result calculation registers
    reg [DATA_W-1:0] result_stage2;
    reg valid_stage2;
    
    // Stage 1: Register inputs and prepare for operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_type_stage1 <= 2'b00;
            operand_stage1 <= 0;
            reg_data_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            op_type_stage1 <= op_type;
            operand_stage1 <= operand;
            reg_data_stage1 <= reg_data;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform operation and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                case(op_type_stage1)
                    2'b00: result_stage2 <= reg_data_stage1 + operand_stage1;
                    2'b01: result_stage2 <= reg_data_stage1 & operand_stage1;
                    2'b10: result_stage2 <= reg_data_stage1 | operand_stage1;
                    2'b11: result_stage2 <= reg_data_stage1 ^ operand_stage1;
                    default: result_stage2 <= reg_data_stage1;
                endcase
            end
        end
    end
    
    // Final stage: Update register data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data <= 0;
        end else if (valid_stage2) begin
            reg_data <= result_stage2;
        end
    end
    
    // Output valid signal
    assign valid_out = valid_stage2;
    
endmodule