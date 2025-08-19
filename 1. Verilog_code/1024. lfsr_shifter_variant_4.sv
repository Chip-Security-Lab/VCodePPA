//SystemVerilog
module lfsr_shifter #(parameter W=8) (
    input clk,
    input rst,
    input start,
    output reg [W-1:0] prbs_out,
    output reg valid_out
);

    // Internal pipeline registers
    reg [W-1:0] prbs_stage1;
    reg valid_stage1;
    reg feedback_stage2;
    reg [W-1:0] prbs_stage2;
    reg valid_stage2;
    reg [W-1:0] prbs_stage3;
    reg valid_stage3;

    // Combined always block for all sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prbs_stage1    <= {W{1'b1}};
            valid_stage1   <= 1'b0;
            feedback_stage2<= 1'b0;
            prbs_stage2    <= {W{1'b1}};
            valid_stage2   <= 1'b0;
            prbs_stage3    <= {W{1'b1}};
            valid_stage3   <= 1'b0;
            prbs_out       <= {W{1'b1}};
            valid_out      <= 1'b0;
        end else begin
            // Stage 1: Capture input or hold
            if (start) begin
                prbs_stage1  <= prbs_stage1;
                valid_stage1 <= 1'b1;
            end else begin
                prbs_stage1  <= prbs_stage1;
                valid_stage1 <= valid_stage1;
            end

            // Stage 2: Calculate feedback and shift
            feedback_stage2 <= prbs_stage1[W-1] ^ prbs_stage1[W-3];
            prbs_stage2     <= {prbs_stage1[W-2:0], prbs_stage1[W-1] ^ prbs_stage1[W-3]};
            valid_stage2    <= valid_stage1;

            // Stage 3: Output register
            prbs_stage3     <= prbs_stage2;
            valid_stage3    <= valid_stage2;

            // Output assignments
            prbs_out        <= prbs_stage3;
            valid_out       <= valid_stage3;
        end
    end

endmodule