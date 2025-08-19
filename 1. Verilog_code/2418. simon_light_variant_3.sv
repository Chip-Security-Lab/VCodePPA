//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: simon_light
// Description: Top level module for SIMON light-weight block cipher
///////////////////////////////////////////////////////////////////////////////
module simon_light #(
    parameter ROUNDS = 44
)(
    input wire clk,
    input wire load_key,
    input wire [63:0] block_in,
    input wire [127:0] key_in,
    output reg [63:0] block_out
);
    // Internal signals
    wire [63:0] key_round;
    wire [31:0] left, right, new_left;
    
    // Key schedule generation submodule instantiation
    key_schedule_generator #(
        .ROUNDS(ROUNDS)
    ) key_gen_inst (
        .clk(clk),
        .load_key(load_key),
        .key_in(key_in),
        .round_key(key_round)
    );
    
    // Block processing submodule instantiation
    block_processor block_proc_inst (
        .block_in(block_in),
        .round_key(key_round[31:0]),
        .left(left),
        .right(right),
        .new_left(new_left)
    );
    
    // Output register control
    always @(posedge clk) begin
        if (!load_key) begin
            block_out <= {right, new_left};
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: key_schedule_generator
// Description: Generates key schedule for SIMON encryption
///////////////////////////////////////////////////////////////////////////////
module key_schedule_generator #(
    parameter ROUNDS = 44
)(
    input wire clk,
    input wire load_key,
    input wire [127:0] key_in,
    output wire [63:0] round_key
);
    // Internal storage for key schedule
    reg [63:0] key_schedule [0:ROUNDS-1];
    
    // Initial key loading logic
    always @(posedge clk) begin
        if (load_key) begin
            key_schedule[0] <= key_in[63:0];
        end
    end
    
    // Key expansion logic for rounds 1 to ROUNDS-1
    integer r;
    always @(posedge clk) begin
        if (load_key) begin
            for(r=1; r<ROUNDS; r=r+1) begin
                // Upper bits rotation
                key_schedule[r][63:3] <= key_schedule[r-1][60:0];
                // Lower bits XOR with constant
                key_schedule[r][2:0] <= key_schedule[r-1][63:61] ^ 3'h5;
            end
        end
    end
    
    // Output the current round key
    assign round_key = key_schedule[0];
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: block_processor
// Description: Processes a single round of SIMON encryption
///////////////////////////////////////////////////////////////////////////////
module block_processor (
    input wire [63:0] block_in,
    input wire [31:0] round_key,
    output wire [31:0] left,
    output wire [31:0] right,
    output wire [31:0] new_left
);
    // Split the input block into left and right halves
    assign left = block_in[63:32];
    assign right = block_in[31:0];
    
    // Core SIMON round function
    simon_round_function round_func_inst (
        .left(left),
        .right(right),
        .round_key(round_key),
        .new_left(new_left)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: simon_round_function
// Description: Implements the core SIMON encryption round function
///////////////////////////////////////////////////////////////////////////////
module simon_round_function (
    input wire [31:0] left,
    input wire [31:0] right,
    input wire [31:0] round_key,
    output wire [31:0] new_left
);
    // Internal signals for rotation operations
    wire [31:0] rotated_left_1;  // Left rotated by 1
    wire [31:0] rotated_left_8;  // Left rotated by 8
    wire [31:0] rotated_left_2;  // Left rotated by 2
    
    // Rotation operations
    assign rotated_left_1 = {left[30:0], left[31]};
    assign rotated_left_8 = {left[23:0], left[31:24]};
    assign rotated_left_2 = {left[29:0], left[31:30]};
    
    // Simon round calculation broken into steps
    wire [31:0] and_result;
    wire [31:0] xor_stage1;
    wire [31:0] xor_stage2;
    
    // Bitwise AND of rotated left values
    assign and_result = rotated_left_1 & rotated_left_8;
    
    // First XOR stage
    assign xor_stage1 = and_result ^ rotated_left_2;
    
    // Final XOR with right and round key
    assign xor_stage2 = xor_stage1 ^ right;
    assign new_left = xor_stage2 ^ round_key;
    
endmodule