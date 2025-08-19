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
    
    // Pipeline registers for instruction decoding
    reg [15:0] instruction_pipe;
    reg [3:0] alu_op_pipe;
    reg [3:0] dst_reg_pipe;
    reg [3:0] src_reg_pipe;
    reg [7:0] immediate_pipe;
    reg mem_read_pipe;
    reg mem_write_pipe;
    reg reg_write_pipe;
    reg immediate_valid_pipe;
    
    // State transition logic - separated from data path
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state computation - combinational logic
    always @(*) begin
        if (state == IDLE) begin
            next_state = ready ? DECODE : IDLE;
        end else if (state == DECODE) begin
            next_state = EXECUTE;
        end else if (state == EXECUTE) begin
            next_state = WRITEBACK;
        end else if (state == WRITEBACK) begin
            next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end
    
    // Pipelined instruction capture - stage 1
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instruction_pipe <= 16'd0;
        end else if (state == IDLE && ready) begin
            instruction_pipe <= instruction;
        end
    end
    
    // Instruction decoding - stage 2
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_op_pipe <= 4'd0;
            dst_reg_pipe <= 4'd0;
            src_reg_pipe <= 4'd0;
            immediate_pipe <= 8'd0;
            mem_read_pipe <= 1'b0;
            mem_write_pipe <= 1'b0;
            reg_write_pipe <= 1'b0;
            immediate_valid_pipe <= 1'b0;
        end else if (state == DECODE) begin
            // Extract fields
            alu_op_pipe <= instruction_pipe[15:12];
            dst_reg_pipe <= instruction_pipe[11:8];
            src_reg_pipe <= instruction_pipe[7:4];
            immediate_pipe <= {4'b0000, instruction_pipe[3:0]};
            
            // Determine operation type
            if (instruction_pipe[15:12] == 4'b0000) begin // NOP
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b0;
                immediate_valid_pipe <= 1'b0;
            end else if (instruction_pipe[15:12] == 4'b0001) begin // ADD
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b1;
                immediate_valid_pipe <= 1'b0;
            end else if (instruction_pipe[15:12] == 4'b0010) begin // SUB
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b1;
                immediate_valid_pipe <= 1'b0;
            end else if (instruction_pipe[15:12] == 4'b0011) begin // ADDI (Add Immediate)
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b1;
                immediate_valid_pipe <= 1'b1;
            end else if (instruction_pipe[15:12] == 4'b0100) begin // LOAD
                mem_read_pipe <= 1'b1;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b1;
                immediate_valid_pipe <= 1'b0;
            end else if (instruction_pipe[15:12] == 4'b0101) begin // STORE
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b1;
                reg_write_pipe <= 1'b0;
                immediate_valid_pipe <= 1'b0;
            end else begin
                mem_read_pipe <= 1'b0;
                mem_write_pipe <= 1'b0;
                reg_write_pipe <= 1'b0;
                immediate_valid_pipe <= 1'b0;
            end
        end
    end
    
    // Output register update - stage 3
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_op <= 4'd0;
            src_reg <= 4'd0;
            dst_reg <= 4'd0;
            immediate <= 8'd0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
            immediate_valid <= 1'b0;
        end else if (state == EXECUTE) begin
            alu_op <= alu_op_pipe;
            src_reg <= src_reg_pipe;
            dst_reg <= dst_reg_pipe;
            immediate <= immediate_pipe;
            mem_read <= mem_read_pipe;
            mem_write <= mem_write_pipe;
            reg_write <= reg_write_pipe;
            immediate_valid <= immediate_valid_pipe;
        end else if (state == WRITEBACK) begin
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
        end else if (state == IDLE) begin
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
            immediate_valid <= 1'b0;
        end
    end
endmodule