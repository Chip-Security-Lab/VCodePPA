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
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= FETCH;
        else
            state <= next_state;
    end
    
    always @(*) begin
        // Default values
        pc_inc = 1'b0;
        acc_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_op = 2'b00;
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
                case (instruction[7:6])
                    2'b00: begin // ADD
                        alu_op = 2'b00;
                        next_state = WRITEBACK;
                    end
                    2'b01: begin // SUB
                        alu_op = 2'b01;
                        next_state = WRITEBACK;
                    end
                    2'b10: begin // STORE
                        mem_write = 1'b1;
                        next_state = FETCH;
                        pc_inc = 1'b1;
                    end
                    2'b11: begin // JUMP if zero
                        if (zero_flag) pc_inc = 1'b0;
                        else pc_inc = 1'b1;
                        next_state = FETCH;
                    end
                endcase
            end
            WRITEBACK: begin
                acc_write = 1'b1;
                pc_inc = 1'b1;
                next_state = FETCH;
            end
        endcase
    end
endmodule