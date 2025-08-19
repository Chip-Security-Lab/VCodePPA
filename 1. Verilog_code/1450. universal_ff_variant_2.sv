//SystemVerilog
module universal_ff (
    input clk, rstn,
    input [1:0] mode,
    input d, j, k, t, s, r,
    output reg q
);
    // Stage 1 - Input registration
    reg [1:0] mode_stage1;
    reg d_stage1, j_stage1, k_stage1, t_stage1, s_stage1, r_stage1;
    reg valid_stage1;
    
    // Stage 2 - Calculation stage
    reg [1:0] mode_stage2;
    reg q_feedback;
    reg q_next;
    reg valid_stage2;
    
    // Stage 1: Register inputs
    always @(posedge clk) begin
        if (!rstn) begin
            mode_stage1 <= 2'b00;
            d_stage1 <= 1'b0;
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            t_stage1 <= 1'b0;
            s_stage1 <= 1'b0;
            r_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            mode_stage1 <= mode;
            d_stage1 <= d;
            j_stage1 <= j;
            k_stage1 <= k;
            t_stage1 <= t;
            s_stage1 <= s;
            r_stage1 <= r;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Register intermediate calculation and propagate valid signal
    always @(posedge clk) begin
        if (!rstn) begin
            mode_stage2 <= 2'b00;
            q_feedback <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            mode_stage2 <= mode_stage1;
            q_feedback <= q;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Calculation logic - Processed in stage 2
    always @(posedge clk) begin
        if (!rstn) begin
            q_next <= 1'b0;
        end
        else if (valid_stage2) begin
            case(mode_stage2)
                2'b00: q_next <= d_stage1;                    // D模式
                2'b01: q_next <= j_stage1 & ~q_feedback | ~k_stage1 & q_feedback;  // JK模式
                2'b10: q_next <= t_stage1 ^ q_feedback;       // T模式
                2'b11: q_next <= s_stage1 | (~r_stage1 & q_feedback);  // SR模式
            endcase
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (!rstn) begin
            q <= 1'b0;
        end
        else begin
            q <= q_next;
        end
    end
endmodule