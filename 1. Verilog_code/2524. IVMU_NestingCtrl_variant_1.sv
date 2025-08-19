//SystemVerilog
// Top module: Manages the nesting level control with a pipelined architecture.
module IVMU_NestingCtrl_pipelined #(parameter LVL = 3) (
    input clk,
    input rst,
    input [LVL-1:0] int_lvl,
    output [LVL-1:0] current_lvl
);

// --- Pipeline Registers ---

// State register (holds the current level)
reg [LVL-1:0] state_reg_current_lvl;

// Stage 1 Registers (capture outputs of Stage 1 combinational logic)
reg s1_reg_int_lvl_is_zero;
reg s1_reg_int_lvl_is_greater;
reg [LVL-1:0] s1_reg_int_lvl;       // Pass through int_lvl
reg [LVL-1:0] s1_reg_current_lvl;   // Pass through state_reg_current_lvl

// --- Combinational Logic Stages ---

// Stage 1 Combinational Logic: Calculate intermediate conditions and pass through inputs
wire int_lvl_is_zero_s1 = (~|int_lvl);
wire int_lvl_is_greater_s1 = (int_lvl > state_reg_current_lvl); // Uses current state feedback
wire [LVL-1:0] int_lvl_s1_pass = int_lvl;
wire [LVL-1:0] current_lvl_s1_pass = state_reg_current_lvl; // Pass through current state

// Stage 2 Combinational Logic: Select the next level based on Stage 1 registered results
wire [LVL-1:0] next_lvl_s2;
assign next_lvl_s2 = s1_reg_int_lvl_is_zero ? {LVL{1'b0}} :
                     s1_reg_int_lvl_is_greater ? s1_reg_int_lvl :
                     s1_reg_current_lvl; // Uses values from Stage 1 registers

// --- Register Updates ---

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all registers
        state_reg_current_lvl <= {LVL{1'b0}};
        s1_reg_int_lvl_is_zero <= 1'b0;
        s1_reg_int_lvl_is_greater <= 1'b0;
        s1_reg_int_lvl <= {LVL{1'b0}};
        s1_reg_current_lvl <= {LVL{1'b0}};
    end else begin
        // Update Stage 1 registers
        s1_reg_int_lvl_is_zero <= int_lvl_is_zero_s1;
        s1_reg_int_lvl_is_greater <= int_lvl_is_greater_s1;
        s1_reg_int_lvl <= int_lvl_s1_pass;
        s1_reg_current_lvl <= current_lvl_s1_pass;

        // Update State register with the result from Stage 2 combinational logic
        state_reg_current_lvl <= next_lvl_s2;
    end
end

// --- Output ---
// The output is the current state
assign current_lvl = state_reg_current_lvl;

endmodule