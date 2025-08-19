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

    // Pipeline registers
    reg [7:0] instruction_stage1;
    reg [7:0] instruction_stage2;
    reg [7:0] instruction_stage3;
    reg zero_flag_stage1;
    reg zero_flag_stage2;
    reg zero_flag_stage3;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    reg valid_stage4;
    
    // Stage 1: Fetch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            instruction_stage1 <= 8'b0;
            zero_flag_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            instruction_stage1 <= instruction;
            zero_flag_stage1 <= zero_flag;
        end
    end
    
    // Stage 2: Decode
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            instruction_stage2 <= 8'b0;
            zero_flag_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            instruction_stage2 <= instruction_stage1;
            zero_flag_stage2 <= zero_flag_stage1;
        end
    end
    
    // Stage 3: Execute
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
            instruction_stage3 <= 8'b0;
            zero_flag_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            instruction_stage3 <= instruction_stage2;
            zero_flag_stage3 <= zero_flag_stage2;
        end
    end
    
    // Stage 4: Writeback
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Control signals generation
    always @(*) begin
        // Default values
        pc_inc = 1'b0;
        acc_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_op = 2'b00;
        
        // Stage 1: Fetch
        if (valid_stage1) begin
            mem_read = 1'b1;
        end
        
        // Stage 3: Execute
        if (valid_stage3) begin
            case (instruction_stage3[7:6])
                2'b00: begin // ADD
                    alu_op = 2'b00;
                end
                2'b01: begin // SUB
                    alu_op = 2'b01;
                end
                2'b10: begin // STORE
                    mem_write = 1'b1;
                    pc_inc = 1'b1;
                end
                2'b11: begin // JUMP if zero
                    if (zero_flag_stage3) pc_inc = 1'b0;
                    else pc_inc = 1'b1;
                end
            endcase
        end
        
        // Stage 4: Writeback
        if (valid_stage4) begin
            if (instruction_stage3[7:6] == 2'b00 || instruction_stage3[7:6] == 2'b01) begin
                acc_write = 1'b1;
                pc_inc = 1'b1;
            end
        end
    end

endmodule