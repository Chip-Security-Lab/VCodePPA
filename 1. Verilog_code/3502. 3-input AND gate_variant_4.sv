//SystemVerilog
//IEEE 1364-2005 Verilog
module and_gate_3 (
    input  wire       clk,        // Clock input
    input  wire       rst_n,      // Active-low reset
    input  wire       a,          // Input A
    input  wire       b,          // Input B
    input  wire       c,          // Input C
    input  wire       req_in,     // Request input (replaces valid)
    output wire       ack_out,    // Acknowledge output (replaces ready)
    output wire       y           // Output Y
);
    // Internal pipeline registers
    reg        stage1_a_reg;
    reg        stage1_b_reg;
    reg        stage1_c_reg;
    reg        stage2_ab_reg;
    reg        result_reg;
    
    // Request-Acknowledge handling registers
    reg        req_stage1;
    reg        req_stage2;
    reg        req_stage3;
    
    // Acknowledge signal generation
    assign ack_out = req_in;
    
    // Stage 1: Register inputs when request is active
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_reg <= 1'b0;
            stage1_b_reg <= 1'b0;
            stage1_c_reg <= 1'b0;
            req_stage1 <= 1'b0;
        end else if (req_in) begin
            stage1_a_reg <= a;
            stage1_b_reg <= b;
            stage1_c_reg <= c;
            req_stage1 <= 1'b1;
        end else begin
            req_stage1 <= 1'b0;
        end
    end

    // Stage 2: Calculate partial product (A & B)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_ab_reg <= 1'b0;
            req_stage2 <= 1'b0;
        end else if (req_stage1) begin
            stage2_ab_reg <= stage1_a_reg & stage1_b_reg;
            req_stage2 <= 1'b1;
        end else begin
            req_stage2 <= 1'b0;
        end
    end

    // Final stage: Complete the AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 1'b0;
            req_stage3 <= 1'b0;
        end else if (req_stage2) begin
            result_reg <= stage2_ab_reg & stage1_c_reg;
            req_stage3 <= 1'b1;
        end else begin
            req_stage3 <= 1'b0;
        end
    end

    // Output assignment
    assign y = result_reg;

endmodule