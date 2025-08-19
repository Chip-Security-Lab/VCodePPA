//SystemVerilog - IEEE 1364-2005
module jkff #(parameter W=1) (
    input wire clk,
    input wire rstn,
    input wire [W-1:0] j, k,
    input wire valid_in,
    output wire valid_out,
    output wire [W-1:0] q
);
    // Stage 1: Input registration
    reg [W-1:0] j_stage1, k_stage1;
    reg valid_stage1;

    // Stage 2: Initial computation - Extract control signals
    reg [W-1:0] j_stage2, k_stage2;
    reg valid_stage2;
    reg [1:0] control_signals_stage2 [W-1:0];
    
    // Stage 3: Prepare next state logic
    reg [W-1:0] q_reg_stage3;
    reg [W-1:0] q_next_part1_stage3;
    reg [W-1:0] control_stage3;
    reg valid_stage3;
    
    // Stage 4: Complete next state calculation
    reg [W-1:0] q_next_stage4;
    reg valid_stage4;
    
    // Stage 5: Output registration
    reg [W-1:0] q_reg;
    reg valid_stage5;

    // Assign outputs
    assign q = q_reg;
    assign valid_out = valid_stage5;

    // Stage 1: Register inputs
    always @(posedge clk) begin
        if (!rstn) begin
            j_stage1 <= 0;
            k_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end
        else begin
            j_stage1 <= j;
            k_stage1 <= k;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Extract and prepare control signals
    always @(posedge clk) begin
        if (!rstn) begin
            j_stage2 <= 0;
            k_stage2 <= 0;
            valid_stage2 <= 1'b0;
            for (int i = 0; i < W; i++) begin
                control_signals_stage2[i] <= 2'b00;
            end
        end
        else begin
            j_stage2 <= j_stage1;
            k_stage2 <= k_stage1;
            valid_stage2 <= valid_stage1;
            
            for (int i = 0; i < W; i++) begin
                control_signals_stage2[i] <= {j_stage1[i], k_stage1[i]};
            end
        end
    end

    // Stage 3: Prepare partial next state calculation
    always @(posedge clk) begin
        if (!rstn) begin
            q_reg_stage3 <= 0;
            q_next_part1_stage3 <= 0;
            control_stage3 <= 0;
            valid_stage3 <= 1'b0;
        end
        else begin
            q_reg_stage3 <= q_reg;
            valid_stage3 <= valid_stage2;
            
            for (int i = 0; i < W; i++) begin
                case (control_signals_stage2[i])
                    2'b10: q_next_part1_stage3[i] <= 1'b1;  // Set
                    2'b01: q_next_part1_stage3[i] <= 1'b0;  // Reset
                    default: q_next_part1_stage3[i] <= q_reg[i]; // Hold or Toggle
                endcase
                
                // Save control for toggle operation in next stage
                control_stage3[i] <= (control_signals_stage2[i] == 2'b11) ? 1'b1 : 1'b0;
            end
        end
    end

    // Stage 4: Complete next state calculation (handle toggle case)
    always @(posedge clk) begin
        if (!rstn) begin
            q_next_stage4 <= 0;
            valid_stage4 <= 1'b0;
        end
        else begin
            valid_stage4 <= valid_stage3;
            
            for (int i = 0; i < W; i++) begin
                // Apply toggle operation if needed
                q_next_stage4[i] <= control_stage3[i] ? ~q_reg_stage3[i] : q_next_part1_stage3[i];
            end
        end
    end

    // Stage 5: Update output register
    always @(posedge clk) begin
        if (!rstn) begin
            q_reg <= 0;
            valid_stage5 <= 1'b0;
        end
        else begin
            valid_stage5 <= valid_stage4;
            
            if (valid_stage4) begin
                q_reg <= q_next_stage4;
            end
        end
    end
endmodule