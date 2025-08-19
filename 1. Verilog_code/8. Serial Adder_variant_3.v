module manchester_carry_adder_pipelined (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] sum,
    output reg valid
);

    // Stage 1: Generate and propagate signals
    reg [7:0] g_stage1, p_stage1;
    reg [7:0] a_stage1, b_stage1;
    reg valid_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage1 <= 8'b0;
            p_stage1 <= 8'b0;
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: First half of carry chain
    reg [3:0] c_stage2;
    reg [7:0] p_stage2;
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_stage2 <= 4'b0;
            p_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            c_stage2[0] <= 1'b0;
            c_stage2[1] <= g_stage1[0] | (p_stage1[0] & 1'b0);
            c_stage2[2] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]) | (p_stage1[1] & p_stage1[0] & 1'b0);
            c_stage2[3] <= g_stage1[2] | (p_stage1[2] & g_stage1[1]) | (p_stage1[2] & p_stage1[1] & g_stage1[0]) | (p_stage1[2] & p_stage1[1] & p_stage1[0] & 1'b0);
            p_stage2 <= p_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Second half of carry chain
    reg [7:0] c_stage3;
    reg [7:0] p_stage3;
    reg valid_stage3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_stage3 <= 8'b0;
            p_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else begin
            c_stage3[3:0] <= c_stage2;
            c_stage3[4] <= g_stage1[3] | (p_stage1[3] & g_stage1[2]) | (p_stage1[3] & p_stage1[2] & g_stage1[1]) | (p_stage1[3] & p_stage1[2] & p_stage1[1] & g_stage1[0]) | (p_stage1[3] & p_stage1[2] & p_stage1[1] & p_stage1[0] & 1'b0);
            c_stage3[5] <= g_stage1[4] | (p_stage1[4] & g_stage1[3]) | (p_stage1[4] & p_stage1[3] & g_stage1[2]) | (p_stage1[4] & p_stage1[3] & p_stage1[2] & g_stage1[1]) | (p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & g_stage1[0]) | (p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & p_stage1[0] & 1'b0);
            c_stage3[6] <= g_stage1[5] | (p_stage1[5] & g_stage1[4]) | (p_stage1[5] & p_stage1[4] & g_stage1[3]) | (p_stage1[5] & p_stage1[4] & p_stage1[3] & g_stage1[2]) | (p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & g_stage1[1]) | (p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & g_stage1[0]) | (p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & p_stage1[0] & 1'b0);
            c_stage3[7] <= g_stage1[6] | (p_stage1[6] & g_stage1[5]) | (p_stage1[6] & p_stage1[5] & g_stage1[4]) | (p_stage1[6] & p_stage1[5] & p_stage1[4] & g_stage1[3]) | (p_stage1[6] & p_stage1[5] & p_stage1[4] & p_stage1[3] & g_stage1[2]) | (p_stage1[6] & p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & g_stage1[1]) | (p_stage1[6] & p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & g_stage1[0]) | (p_stage1[6] & p_stage1[5] & p_stage1[4] & p_stage1[3] & p_stage1[2] & p_stage1[1] & p_stage1[0] & 1'b0);
            p_stage3 <= p_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Final sum calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'b0;
            valid <= 1'b0;
        end else begin
            sum <= p_stage3 ^ c_stage3;
            valid <= valid_stage3;
        end
    end

endmodule