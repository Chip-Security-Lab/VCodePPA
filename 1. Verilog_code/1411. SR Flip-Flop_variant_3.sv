//SystemVerilog
module sr_flip_flop (
    input wire clk,
    input wire rst_n,      // Reset signal (active low)
    input wire s,
    input wire r,
    input wire valid_in,   // Input valid signal
    output wire valid_out, // Output valid signal
    output wire q
);
    // Stage 1 - Input Registration
    reg s_stage1, r_stage1;
    reg valid_stage1;
    
    // Stage 2 - Logic Processing
    reg op_result_stage2;
    reg valid_stage2;
    
    // Stage 3 - Output Registration
    reg q_stage3;
    reg valid_stage3;

    // Stage 1 input registration - S signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_stage1 <= 1'b0;
        end else begin
            s_stage1 <= s;
        end
    end

    // Stage 1 input registration - R signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_stage1 <= 1'b0;
        end else begin
            r_stage1 <= r;
        end
    end

    // Stage 1 input registration - valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2 - SR logic processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_result_stage2 <= 1'b0;
        end else begin
            case ({s_stage1, r_stage1})
                2'b00: op_result_stage2 <= q_stage3;  // No change, use feedback
                2'b01: op_result_stage2 <= 1'b0;      // Reset
                2'b10: op_result_stage2 <= 1'b1;      // Set
                2'b11: op_result_stage2 <= 1'bx;      // Invalid - undefined
            endcase
        end
    end

    // Stage 2 - valid signal propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3 - Output registration for q
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage3 <= 1'b0;
        end else begin
            q_stage3 <= op_result_stage2;
        end
    end

    // Stage 3 - Output registration for valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
        end
    end

    // Assign outputs
    assign q = q_stage3;
    assign valid_out = valid_stage3;

endmodule