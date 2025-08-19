//SystemVerilog
module micro_control_unit(
    input wire clk,
    input wire rst,
    input wire [7:0] instruction,
    input wire zero_flag,
    output reg pc_inc,
    output reg acc_write,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] alu_op
);
    parameter [1:0] FETCH = 2'b00, DECODE = 2'b01, 
                    EXECUTE = 2'b10, WRITEBACK = 2'b11;
    reg [1:0] state, next_state;
    
    // Pre-compute instruction type
    wire [1:0] instr_type = instruction[7:6];
    wire is_jump = (instr_type == 2'b11);
    wire is_store = (instr_type == 2'b10);
    wire is_arith = (instr_type == 2'b00 || instr_type == 2'b01);
    
    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= FETCH;
        else
            state <= next_state;
    end
    
    // Control signal generation
    always @(*) begin
        // Default values
        {pc_inc, acc_write, mem_read, mem_write, alu_op} = 6'b0_0_0_0_00;
        next_state = state;
        
        case (state)
            FETCH: begin
                mem_read = 1'b1;
                next_state = DECODE;
            end
            DECODE: begin
                next_state = EXECUTE;
            end
            EXECUTE: begin
                if (is_arith) begin
                    alu_op = instr_type;
                    next_state = WRITEBACK;
                end
                else if (is_store) begin
                    mem_write = 1'b1;
                    pc_inc = 1'b1;
                    next_state = FETCH;
                end
                else if (is_jump) begin
                    pc_inc = ~zero_flag;
                    next_state = FETCH;
                end
            end
            WRITEBACK: begin
                acc_write = 1'b1;
                pc_inc = 1'b1;
                next_state = FETCH;
            end
        endcase
    end
endmodule