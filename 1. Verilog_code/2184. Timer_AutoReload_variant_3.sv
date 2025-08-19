//SystemVerilog
// Timer_AutoReload with pipelined architecture and parallel prefix subtractor
module Timer_AutoReload #(parameter VAL=255) (
    input wire clk,
    input wire en,
    input wire rst,
    output reg alarm
);
    // Stage 1 registers
    reg [7:0] cnt_stage1;
    reg en_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] cnt_stage2;
    reg cnt_zero_stage2;
    reg valid_stage2;
    
    // Parallel prefix subtractor signals
    wire [7:0] next_cnt;
    wire [7:0] minuend, subtrahend;
    wire [7:0] p, g; // Propagate and generate signals
    wire [7:0] c;    // Carry signals
    
    // Input to subtractor
    assign minuend = cnt_stage1;
    assign subtrahend = 8'd1;
    
    // Generate propagate and generate signals (p_i = a_i XOR b_i, g_i = a_i AND !b_i)
    assign p = minuend ^ subtrahend;
    assign g = minuend & ~subtrahend;
    
    // Parallel prefix carry computation - Kogge-Stone implementation
    // Level 1
    wire [7:0] p_l1, g_l1;
    assign p_l1[0] = p[0];
    assign g_l1[0] = g[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : level1
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            assign p_l1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Level 2
    wire [7:0] p_l2, g_l2;
    assign p_l2[0] = p_l1[0];
    assign g_l2[0] = g_l1[0];
    assign p_l2[1] = p_l1[1];
    assign g_l2[1] = g_l1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
    
    // Level 3
    wire [7:0] p_l3, g_l3;
    assign p_l3[0] = p_l2[0];
    assign g_l3[0] = g_l2[0];
    assign p_l3[1] = p_l2[1];
    assign g_l3[1] = g_l2[1];
    assign p_l3[2] = p_l2[2];
    assign g_l3[2] = g_l2[2];
    assign p_l3[3] = p_l2[3];
    assign g_l3[3] = g_l2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : level3
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
        end
    endgenerate
    
    // Compute carries
    assign c[0] = 1'b1; // Borrow in for subtraction
    assign c[1] = g_l3[0];
    assign c[2] = g_l3[1];
    assign c[3] = g_l3[2];
    assign c[4] = g_l3[3];
    assign c[5] = g_l3[4];
    assign c[6] = g_l3[5];
    assign c[7] = g_l3[6];
    
    // Final sum computation
    assign next_cnt = p ^ c;
    
    // Pipeline stage 1: Counter management with parallel prefix subtractor
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage1 <= VAL;
            en_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            en_stage1 <= en;
            valid_stage1 <= en;
            
            if (en) begin
                if (cnt_stage1 == 0)
                    cnt_stage1 <= VAL;
                else
                    cnt_stage1 <= next_cnt;
            end
        end
    end
    
    // Pipeline stage 2: Zero detection and alarm generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= 0;
            cnt_zero_stage2 <= 0;
            valid_stage2 <= 0;
            alarm <= 0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            cnt_zero_stage2 <= (cnt_stage1 == 0);
            valid_stage2 <= valid_stage1;
            
            if (valid_stage2)
                alarm <= cnt_zero_stage2;
        end
    end
endmodule