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

    // Instantiate submodules
    wire [7:0] instruction_out_stage1;
    wire zero_flag_out_stage1;
    wire mem_read_out_stage1;
    wire valid_stage1;

    wire [7:0] instruction_out_stage2;
    wire zero_flag_out_stage2;
    wire [1:0] alu_op_out_stage2;
    wire valid_stage2;

    wire mem_write_out_stage3;
    wire pc_inc_out_stage3;
    wire valid_stage3;

    // Stage 1: Fetch
    fetch_stage fetch_inst (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .zero_flag(zero_flag),
        .valid(valid_stage1),
        .instruction_out(instruction_out_stage1),
        .zero_flag_out(zero_flag_out_stage1),
        .mem_read_out(mem_read_out_stage1)
    );

    // Stage 2: Decode
    decode_stage decode_inst (
        .clk(clk),
        .rst(rst),
        .valid(valid_stage1),
        .instruction_in(instruction_out_stage1),
        .zero_flag_in(zero_flag_out_stage1),
        .alu_op_out(alu_op_out_stage2),
        .valid_out(valid_stage2),
        .instruction_out(instruction_out_stage2),
        .zero_flag_out(zero_flag_out_stage2)
    );

    // Stage 3: Execute
    execute_stage execute_inst (
        .clk(clk),
        .rst(rst),
        .valid(valid_stage2),
        .instruction_in(instruction_out_stage2),
        .zero_flag_in(zero_flag_out_stage2),
        .mem_write_out(mem_write_out_stage3),
        .pc_inc_out(pc_inc_out_stage3),
        .valid_out(valid_stage3)
    );

    // Stage 4: Writeback
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_inc <= 1'b0;
            acc_write <= 1'b0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            alu_op <= 2'b00;
        end else if (valid_stage3) begin
            case (instruction_out_stage2[7:6])
                2'b00, 2'b01: begin // ADD/SUB
                    acc_write <= 1'b1;
                    pc_inc <= 1'b1;
                    alu_op <= alu_op_out_stage2;
                end
                2'b10: begin // STORE
                    mem_write <= mem_write_out_stage3;
                    pc_inc <= pc_inc_out_stage3;
                end
                2'b11: begin // JUMP
                    pc_inc <= pc_inc_out_stage3;
                end
            endcase
            mem_read <= mem_read_out_stage1;
        end
    end

endmodule

// Fetch Stage Module
module fetch_stage(
    input wire clk,
    input wire rst,
    input wire [7:0] instruction,
    input wire zero_flag,
    output reg valid,
    output reg [7:0] instruction_out,
    output reg zero_flag_out,
    output reg mem_read_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 1'b0;
            instruction_out <= 8'b0;
            zero_flag_out <= 1'b0;
            mem_read_out <= 1'b0;
        end else begin
            valid <= 1'b1;
            instruction_out <= instruction;
            zero_flag_out <= zero_flag;
            mem_read_out <= 1'b1;
        end
    end
endmodule

// Decode Stage Module
module decode_stage(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [7:0] instruction_in,
    input wire zero_flag_in,
    output reg [1:0] alu_op_out,
    output reg valid_out,
    output reg [7:0] instruction_out,
    output reg zero_flag_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
            instruction_out <= 8'b0;
            zero_flag_out <= 1'b0;
            alu_op_out <= 2'b00;
        end else if (valid) begin
            valid_out <= 1'b1;
            instruction_out <= instruction_in;
            zero_flag_out <= zero_flag_in;
            case (instruction_in[7:6])
                2'b00: alu_op_out <= 2'b00; // ADD
                2'b01: alu_op_out <= 2'b01; // SUB
                default: alu_op_out <= 2'b00;
            endcase
        end
    end
endmodule

// Execute Stage Module
module execute_stage(
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [7:0] instruction_in,
    input wire zero_flag_in,
    output reg mem_write_out,
    output reg pc_inc_out,
    output reg valid_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
            mem_write_out <= 1'b0;
            pc_inc_out <= 1'b0;
        end else if (valid) begin
            valid_out <= 1'b1;
            case (instruction_in[7:6])
                2'b10: begin // STORE
                    mem_write_out <= 1'b1;
                    pc_inc_out <= 1'b1;
                end
                2'b11: begin // JUMP
                    pc_inc_out <= ~zero_flag_in;
                end
                default: begin
                    mem_write_out <= 1'b0;
                    pc_inc_out <= 1'b0;
                end
            endcase
        end
    end
endmodule