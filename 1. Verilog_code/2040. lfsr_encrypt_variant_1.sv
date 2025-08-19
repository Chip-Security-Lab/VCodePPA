//SystemVerilog
module lfsr_encrypt #(
    parameter SEED = 8'hFF,
    parameter POLY = 8'h1D
)(
    input              clk,
    input              rst_n,
    input      [7:0]   data_in,
    output reg [7:0]   encrypted
);

    // Stage 1: LFSR state register
    reg  [7:0] lfsr_state_stage1;
    wire [7:0] lfsr_state_next;

    // Stage 2: LFSR pipeline register
    reg  [7:0] lfsr_state_stage2;

    // Stage 3: Data input pipeline register
    reg  [7:0] data_in_stage2;

    // Stage 4: Encrypted output register (final stage)
    reg  [7:0] encrypted_stage3;

    // Simplified LFSR next-state combinational logic using Boolean algebra
    assign lfsr_state_next = {
        lfsr_state_stage1[6],
        lfsr_state_stage1[5],
        lfsr_state_stage1[4],
        lfsr_state_stage1[3] ^ (lfsr_state_stage1[7] & POLY[3]),
        lfsr_state_stage1[2] ^ (lfsr_state_stage1[7] & POLY[2]),
        lfsr_state_stage1[1] ^ (lfsr_state_stage1[7] & POLY[1]),
        lfsr_state_stage1[0] ^ (lfsr_state_stage1[7] & POLY[0]),
        (lfsr_state_stage1[7] & POLY[7])
    };

    // Stage 1: LFSR state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_state_stage1 <= SEED;
        else
            lfsr_state_stage1 <= lfsr_state_next;
    end

    // Stage 2: Pipeline register for LFSR and data_in
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_stage2 <= SEED;
            data_in_stage2    <= 8'b0;
        end else begin
            lfsr_state_stage2 <= lfsr_state_stage1;
            data_in_stage2    <= data_in;
        end
    end

    // Stage 3: Encrypted data calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encrypted_stage3 <= 8'b0;
        else
            encrypted_stage3 <= data_in_stage2 ^ lfsr_state_stage2;
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encrypted <= 8'b0;
        else
            encrypted <= encrypted_stage3;
    end

endmodule