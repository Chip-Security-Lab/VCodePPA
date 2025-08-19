//SystemVerilog
module pl_reg_dual_edge #(
    parameter W = 8  // Data width parameter
) (
    input  wire         clk,   // System clock
    input  wire         load,  // Load enable signal
    input  wire         rstn,  // Active-low reset
    input  wire [W-1:0] d,     // Data input
    output reg  [W-1:0] q      // Data output
);
    // Pipeline stage registers
    reg [W-1:0] q_pos_stage1;  // Positive edge capture - stage 1
    reg [W-1:0] q_neg_stage1;  // Negative edge capture - stage 1
    reg [W-1:0] q_pos;         // Positive edge buffer - final stage
    reg [W-1:0] q_neg;         // Negative edge buffer - final stage
    
    // Clock state detection with fast recovery
    reg clk_state_p, clk_state_n;

    // ===== POSITIVE EDGE DATA PATH =====
    // Combined stage processing for positive edge to reduce logic depth
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_pos_stage1 <= {W{1'b0}};
            q_pos <= {W{1'b0}};
            clk_state_p <= 1'b0;
        end else begin
            if (load) begin
                q_pos_stage1 <= d;
            end
            q_pos <= q_pos_stage1;
            clk_state_p <= 1'b1;
        end
    end

    // ===== NEGATIVE EDGE DATA PATH =====
    // Combined stage processing for negative edge to reduce logic depth
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            q_neg_stage1 <= {W{1'b0}};
            q_neg <= {W{1'b0}};
            clk_state_n <= 1'b0;
        end else begin
            if (load) begin
                q_neg_stage1 <= d;
            end
            q_neg <= q_neg_stage1;
            clk_state_n <= 1'b1;
        end
    end
    
    // ===== OUTPUT SELECTION LOGIC =====
    // Improved multiplexer with dual clock state tracking
    // This provides better glitch immunity and faster transitions
    always @(*) begin
        if (clk) begin
            q = clk_state_p ? q_pos : q_neg;
        end else begin
            q = clk_state_n ? q_neg : q_pos;
        end
    end

endmodule