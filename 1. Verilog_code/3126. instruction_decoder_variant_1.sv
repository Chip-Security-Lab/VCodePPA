//SystemVerilog
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
                    decode_instruction(instruction);
                end
                EXECUTE: begin
                    // Maintain control signals during execution
                end
                WRITEBACK: begin
                    clear_signals();
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

    // Decode instruction and set control signals
    task decode_instruction(input [15:0] instr);
        begin
            alu_op <= instr[15:12];
            dst_reg <= instr[11:8];
            src_reg <= instr[7:4];
            immediate <= {4'b0000, instr[3:0]};
            case (instr[15:12])
                4'b0000: begin // NOP
                    set_control_signals(1'b0, 1'b0, 1'b0, 1'b0);
                end
                4'b0001: begin // ADD
                    set_control_signals(1'b0, 1'b0, 1'b1, 1'b0);
                end
                4'b0010: begin // SUB
                    set_control_signals(1'b0, 1'b0, 1'b1, 1'b0);
                end
                4'b0011: begin // ADDI
                    set_control_signals(1'b0, 1'b0, 1'b1, 1'b1);
                end
                4'b0100: begin // LOAD
                    set_control_signals(1'b1, 1'b0, 1'b1, 1'b0);
                end
                4'b0101: begin // STORE
                    set_control_signals(1'b0, 1'b1, 1'b0, 1'b0);
                end
                default: begin
                    set_control_signals(1'b0, 1'b0, 1'b0, 1'b0);
                end
            endcase
        end
    endtask

    // Set control signals
    task set_control_signals(input reg read, input reg write, input reg reg_w, input reg immediate_val);
        begin
            mem_read <= read;
            mem_write <= write;
            reg_write <= reg_w;
            immediate_valid <= immediate_val;
        end
    endtask

    // Clear control signals
    task clear_signals();
        begin
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
        end
    endtask

endmodule