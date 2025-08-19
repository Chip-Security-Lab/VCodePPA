module instruction_decoder(
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,
    input wire ready,
    output reg [3:0] alu_op,
    output reg [3:0] src_reg,
    output reg [3:0] dst_reg,
    output reg [7:0] immediate,
    output reg mem_read,
    output reg mem_write,
    output reg reg_write,
    output reg immediate_valid
);
    parameter [1:0] IDLE = 2'b00, DECODE = 2'b01, 
                    EXECUTE = 2'b10, WRITEBACK = 2'b11;
    reg [1:0] state, next_state;
    
    // Instruction formats
    // [15:12] opcode, [11:8] dst, [7:4] src1, [3:0] src2/immediate
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            alu_op <= 4'd0;
            src_reg <= 4'd0;
            dst_reg <= 4'd0;
            immediate <= 8'd0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
            immediate_valid <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                    immediate_valid <= 1'b0;
                end
                DECODE: begin
                    // Extract fields
                    alu_op <= instruction[15:12];
                    dst_reg <= instruction[11:8];
                    src_reg <= instruction[7:4];
                    immediate <= {4'b0000, instruction[3:0]};
                    
                    // Determine operation type
                    case (instruction[15:12])
                        4'b0000: begin // NOP
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                        4'b0001: begin // ADD
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0010: begin // SUB
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0011: begin // ADDI (Add Immediate)
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b1;
                        end
                        4'b0100: begin // LOAD
                            mem_read <= 1'b1;
                            mem_write <= 1'b0;
                            reg_write <= 1'b1;
                            immediate_valid <= 1'b0;
                        end
                        4'b0101: begin // STORE
                            mem_read <= 1'b0;
                            mem_write <= 1'b1;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                        default: begin
                            mem_read <= 1'b0;
                            mem_write <= 1'b0;
                            reg_write <= 1'b0;
                            immediate_valid <= 1'b0;
                        end
                    endcase
                end
                EXECUTE: begin
                    // Maintain control signals during execution
                end
                WRITEBACK: begin
                    // Clear signals after execution
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = ready ? DECODE : IDLE;
            end
            DECODE: begin
                next_state = EXECUTE;
            end
            EXECUTE: begin
                next_state = WRITEBACK;
            end
            WRITEBACK: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
