//SystemVerilog
module jk_flip_flop (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    input wire valid_in,
    output wire valid_out,
    output reg q
);
    // Stage 1: Input Registration
    reg j_stage1, k_stage1;
    reg valid_stage1;
    
    // Stage 2: Operation Determination
    reg [1:0] op_stage2;
    reg q_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1: Register inputs with optimized reset structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            j_stage1 <= j;
            k_stage1 <= k;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Combine operation determination with pre-computed control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_stage2 <= 2'b00;
            q_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Pack J and K into a single control word for more efficient decoding
            op_stage2 <= {j_stage1, k_stage1};
            q_stage2 <= q;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Execute operation with optimized comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end else if (valid_stage2) begin
            // Optimized case implementation using priority encoding
            // This matches better with hardware comparator structures
            if (op_stage2 == 2'b01)
                q <= 1'b0;         // Reset (K=1, J=0)
            else if (op_stage2 == 2'b10)
                q <= 1'b1;         // Set (J=1, K=0)
            else if (op_stage2 == 2'b11)
                q <= ~q_stage2;    // Toggle (J=1, K=1)
            else
                q <= q_stage2;     // No change (J=0, K=0)
        end
    end
    
    // Output valid signal - registered for better timing
    assign valid_out = valid_stage2;
    
endmodule