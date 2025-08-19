//SystemVerilog
// SystemVerilog - Transformed with increased pipeline depth

module IVMU_FixedPriority #(parameter WIDTH=8, ADDR=4) (
    input clk, rst_n,
    input [WIDTH-1:0] int_req,
    output reg [ADDR-1:0] vec_addr
);

// Pipeline registers for Stage 1 (Input -> Stage 1 logic -> Stage 2 registers)
reg [WIDTH-1:0] int_req_stage1;
reg hit_p7_stage1;       // Flag indicating if priority 7 was hit (from int_req)

// Pipeline registers for Stage 2 (Stage 1 logic results -> Stage 2 logic -> Stage 3 registers)
reg [ADDR-1:0] vec_addr_stage2; // Result after checking p7 and p6
reg hit_stage2;                 // Flag indicating if p7 or p6 was hit

// Pipeline registers for Stage 3 (Stage 2 logic results -> Output register)
reg [ADDR-1:0] vec_addr_stage3; // Result after checking p7, p6, and p5

// Combinational logic for Stage 2
wire [ADDR-1:0] vec_addr_stage2_comb;
wire hit_stage2_comb;

// In Stage 2, check p7 (from Stage 1) and p6 (from Stage 1's int_req)
// This logic determines the highest priority hit among p7 and p6
assign vec_addr_stage2_comb = hit_p7_stage1    ? 4'h7 : // If priority 7 was hit in stage 0/1
                              int_req_stage1[6] ? 4'h6 : // Else, if priority 6 is hit in stage 0/1's request
                              'x; // Use 'x or a specific default if neither hit, indicates no hit yet in this stage's check

assign hit_stage2_comb = hit_p7_stage1 | int_req_stage1[6]; // Indicates if p7 or p6 was hit

// Combinational logic for Stage 3
wire [ADDR-1:0] vec_addr_stage3_comb;

// In Stage 3, check result from Stage 2 and p5 (from Stage 1's int_req)
// This logic determines the highest priority hit among p7, p6 (from previous stages) and p5
assign vec_addr_stage3_comb = hit_stage2         ? vec_addr_stage2 : // If p7 or p6 was hit (result from Stage 2 comb registered)
                              int_req_stage1[5] ? 4'h5 :       // Else, if priority 5 is hit (from Stage 1 registered int_req)
                              4'h0;                            // Default case if no priority hit

// Registered logic for all pipeline stages
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registered signals
        int_req_stage1 <= 0;
        hit_p7_stage1 <= 0;

        vec_addr_stage2 <= 0;
        hit_stage2 <= 0;

        vec_addr_stage3 <= 0; // This will become the output vec_addr
        vec_addr <= 0; // Final output register
    end else begin
        // Stage 1: Register input and perform initial priority 7 check
        // Data for int_req at cycle N is registered.
        // hit_p7_stage1 is calculated based on int_req at cycle N.
        int_req_stage1 <= int_req;
        hit_p7_stage1 <= int_req[7]; // Check priority 7 directly from current input

        // Stage 2: Register results of checking p7 and p6 based on Stage 1 outputs.
        // These results are for int_req at cycle N.
        // Calculation uses int_req_stage1 (N) and hit_p7_stage1 (N).
        // Results are registered at cycle N+1.
        vec_addr_stage2 <= vec_addr_stage2_comb;
        hit_stage2 <= hit_stage2_comb;

        // Stage 3: Register final result based on Stage 2 outputs and p5 from Stage 1.
        // This result is for int_req at cycle N.
        // Calculation uses vec_addr_stage2 (N+1), hit_stage2 (N+1), and int_req_stage1[5] (N).
        // Result is registered at cycle N+2.
        vec_addr_stage3 <= vec_addr_stage3_comb;

        // Final output register (optional but good practice for synchronous output)
        // Output vec_addr at cycle N+3 holds the result for int_req at cycle N.
        vec_addr <= vec_addr_stage3;
    end
end

endmodule