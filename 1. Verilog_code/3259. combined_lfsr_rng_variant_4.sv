//SystemVerilog
module combined_lfsr_rng (
    input wire clk,
    input wire n_rst,
    output wire [31:0] random_value
);

// Internal wires for combinational logic
wire feedback1_comb;
wire feedback2_comb;
wire [16:0] lfsr1_next_comb;
wire [18:0] lfsr2_next_comb;
wire [15:0] lfsr1_out_comb;
wire [15:0] lfsr2_out_comb;

// Stage 1 registers: LFSR state storage
reg [16:0] lfsr1_state_reg;
reg [18:0] lfsr2_state_reg;

// Stage 2 registers: Feedback and state pipeline
reg feedback1_reg;
reg feedback2_reg;
reg [16:0] lfsr1_state_stage2_reg;
reg [18:0] lfsr2_state_stage2_reg;

// Stage 3 registers: Next-state pipeline
reg [16:0] lfsr1_next_reg;
reg [18:0] lfsr2_next_reg;

// Stage 4 registers: Output extraction pipeline
reg [15:0] lfsr1_out_reg;
reg [15:0] lfsr2_out_reg;

// Stage 5 registers: Output register
reg [15:0] lfsr1_final_reg;
reg [15:0] lfsr2_final_reg;

// --------------------
// Combinational logic
// --------------------

assign feedback1_comb = lfsr1_state_reg[16] ^ lfsr1_state_reg[13];
assign feedback2_comb = lfsr2_state_reg[18] ^ lfsr2_state_reg[17] ^ lfsr2_state_reg[11] ^ lfsr2_state_reg[0];

assign lfsr1_next_comb = {lfsr1_state_stage2_reg[15:0], feedback1_reg};
assign lfsr2_next_comb = {lfsr2_state_stage2_reg[17:0], feedback2_reg};

assign lfsr1_out_comb = lfsr1_next_reg[15:0];
assign lfsr2_out_comb = lfsr2_next_reg[15:0];

// --------------------
// Sequential logic
// --------------------

// Stage 1: Initial LFSR state or propagate previous
always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        lfsr1_state_reg <= 17'h1ACEF;
        lfsr2_state_reg <= 19'h5B4FC;
    end else begin
        lfsr1_state_reg <= lfsr1_next_reg;
        lfsr2_state_reg <= lfsr2_next_reg;
    end
end

// Stage 2: Pipeline feedback and state
always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        feedback1_reg <= 1'b0;
        feedback2_reg <= 1'b0;
        lfsr1_state_stage2_reg <= 17'h1ACEF;
        lfsr2_state_stage2_reg <= 19'h5B4FC;
    end else begin
        feedback1_reg <= feedback1_comb;
        feedback2_reg <= feedback2_comb;
        lfsr1_state_stage2_reg <= lfsr1_state_reg;
        lfsr2_state_stage2_reg <= lfsr2_state_reg;
    end
end

// Stage 3: Next LFSR state pipeline
always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        lfsr1_next_reg <= 17'h1ACEF;
        lfsr2_next_reg <= 19'h5B4FC;
    end else begin
        lfsr1_next_reg <= lfsr1_next_comb;
        lfsr2_next_reg <= lfsr2_next_comb;
    end
end

// Stage 4: Extract output bits
always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        lfsr1_out_reg <= 16'h0000;
        lfsr2_out_reg <= 16'h0000;
    end else begin
        lfsr1_out_reg <= lfsr1_out_comb;
        lfsr2_out_reg <= lfsr2_out_comb;
    end
end

// Stage 5: Output register (final pipeline stage)
always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        lfsr1_final_reg <= 16'h0000;
        lfsr2_final_reg <= 16'h0000;
    end else begin
        lfsr1_final_reg <= lfsr1_out_reg;
        lfsr2_final_reg <= lfsr2_out_reg;
    end
end

assign random_value = {lfsr1_final_reg, lfsr2_final_reg};

endmodule