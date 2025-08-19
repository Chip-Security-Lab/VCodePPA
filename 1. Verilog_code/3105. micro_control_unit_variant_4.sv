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
    
    // State register update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            FETCH:    next_state = DECODE;
            DECODE:   next_state = EXECUTE;
            EXECUTE:  next_state = (instruction[7:6] == 2'b10 || instruction[7:6] == 2'b11) ? FETCH : WRITEBACK;
            WRITEBACK: next_state = FETCH;
            default:  next_state = FETCH;
        endcase
    end
    
    // Memory control signals
    always @(*) begin
        mem_read = (state == FETCH);
        mem_write = (state == EXECUTE && instruction[7:6] == 2'b10);
    end
    
    // ALU operation control
    always @(*) begin
        case (state)
            EXECUTE: begin
                case (instruction[7:6])
                    2'b00: alu_op = 2'b00;  // ADD
                    2'b01: alu_op = 2'b01;  // SUB
                    default: alu_op = 2'b00;
                endcase
            end
            default: alu_op = 2'b00;
        endcase
    end
    
    // Accumulator and PC control
    always @(*) begin
        case (state)
            EXECUTE: begin
                pc_inc = (instruction[7:6] == 2'b10) || 
                        (instruction[7:6] == 2'b11 && ~zero_flag);
            end
            WRITEBACK: begin
                pc_inc = 1'b1;
                acc_write = 1'b1;
            end
            default: begin
                pc_inc = 1'b0;
                acc_write = 1'b0;
            end
        endcase
    end
endmodule