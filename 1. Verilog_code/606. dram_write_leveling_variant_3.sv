//SystemVerilog
module dram_write_leveling #(
    parameter DQ_BITS = 8
)(
    input clk,
    input rst_n,
    input training_en,
    output reg [DQ_BITS-1:0] dqs_pattern
);

    // Stage 1 registers
    reg [2:0] phase_counter_stage1;
    reg training_en_stage1;
    
    // Stage 2 registers
    reg [2:0] phase_counter_stage2;
    reg training_en_stage2;
    reg [2:0] g_stage2, p_stage2;
    
    // Stage 3 registers
    reg [2:0] phase_counter_stage3;
    reg training_en_stage3;
    reg [1:0] g1_stage3, p1_stage3;
    
    // Stage 4 registers
    reg [2:0] phase_counter_stage4;
    reg training_en_stage4;
    reg [2:0] g_final_stage4, p_final_stage4;
    
    // Stage 5 registers
    reg [2:0] phase_counter_stage5;
    reg training_en_stage5;
    reg [2:0] phase_counter_plus_1_stage5;
    
    // Stage 1 logic
    wire [2:0] phase_counter_next = training_en ? phase_counter_stage5 + 1 : 3'b0;
    
    // Stage 2 logic
    wire [2:0] g, p;
    assign g[0] = phase_counter_stage2[0] & 1'b1;
    assign p[0] = phase_counter_stage2[0] ^ 1'b1;
    assign g[1] = phase_counter_stage2[1] & phase_counter_stage2[0];
    assign p[1] = phase_counter_stage2[1] ^ phase_counter_stage2[0];
    assign g[2] = phase_counter_stage2[2] & phase_counter_stage2[1];
    assign p[2] = phase_counter_stage2[2] ^ phase_counter_stage2[1];
    
    // Stage 3 logic
    wire [1:0] g1, p1;
    assign g1[0] = g_stage2[1] | (p_stage2[1] & g_stage2[0]);
    assign p1[0] = p_stage2[1] & p_stage2[0];
    assign g1[1] = g_stage2[2] | (p_stage2[2] & g_stage2[1]);
    assign p1[1] = p_stage2[2] & p_stage2[1];
    
    // Stage 4 logic
    wire [2:0] g_final, p_final;
    assign g_final[0] = g_stage2[0];
    assign p_final[0] = p_stage2[0];
    assign g_final[1] = g1_stage3[0];
    assign p_final[1] = p1_stage3[0];
    assign g_final[2] = g1_stage3[1] | (p1_stage3[1] & g1_stage3[0]);
    assign p_final[2] = p1_stage3[1] & p1_stage3[0];
    
    // Stage 5 logic
    wire [2:0] phase_counter_plus_1;
    assign phase_counter_plus_1[0] = p_stage2[0] ^ 1'b1;
    assign phase_counter_plus_1[1] = p_stage2[1] ^ g_stage2[0];
    assign phase_counter_plus_1[2] = p_stage2[2] ^ g1_stage3[0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_counter_stage1 <= 3'b0;
            training_en_stage1 <= 1'b0;
            phase_counter_stage2 <= 3'b0;
            training_en_stage2 <= 1'b0;
            g_stage2 <= 3'b0;
            p_stage2 <= 3'b0;
            phase_counter_stage3 <= 3'b0;
            training_en_stage3 <= 1'b0;
            g1_stage3 <= 2'b0;
            p1_stage3 <= 2'b0;
            phase_counter_stage4 <= 3'b0;
            training_en_stage4 <= 1'b0;
            g_final_stage4 <= 3'b0;
            p_final_stage4 <= 3'b0;
            phase_counter_stage5 <= 3'b0;
            training_en_stage5 <= 1'b0;
            phase_counter_plus_1_stage5 <= 3'b0;
            dqs_pattern <= {DQ_BITS{1'b0}};
        end else begin
            // Stage 1
            phase_counter_stage1 <= phase_counter_next;
            training_en_stage1 <= training_en;
            
            // Stage 2
            phase_counter_stage2 <= phase_counter_stage1;
            training_en_stage2 <= training_en_stage1;
            g_stage2 <= g;
            p_stage2 <= p;
            
            // Stage 3
            phase_counter_stage3 <= phase_counter_stage2;
            training_en_stage3 <= training_en_stage2;
            g1_stage3 <= g1;
            p1_stage3 <= p1;
            
            // Stage 4
            phase_counter_stage4 <= phase_counter_stage3;
            training_en_stage4 <= training_en_stage3;
            g_final_stage4 <= g_final;
            p_final_stage4 <= p_final;
            
            // Stage 5
            phase_counter_stage5 <= phase_counter_stage4;
            training_en_stage5 <= training_en_stage4;
            phase_counter_plus_1_stage5 <= phase_counter_plus_1;
            
            // Output
            dqs_pattern <= {DQ_BITS{phase_counter_stage5[2]}};
        end
    end
endmodule