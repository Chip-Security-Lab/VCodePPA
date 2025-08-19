module brent_kung_adder(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  a,
    input  wire [3:0]  b, 
    input  wire        cin,
    output reg  [3:0]  sum,
    output reg         cout
);

    // Stage 1: Generate and Propagate signals
    reg [3:0] g_stage1, p_stage1;
    reg [3:0] a_stage1, b_stage1;
    reg       cin_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage1 <= 4'b0;
            p_stage1 <= 4'b0;
            a_stage1 <= 4'b0;
            b_stage1 <= 4'b0;
            cin_stage1 <= 1'b0;
        end else begin
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
            a_stage1 <= a;
            b_stage1 <= b;
            cin_stage1 <= cin;
        end
    end

    // Stage 2: First level prefix computation
    reg [1:0] g_01_stage2, p_01_stage2;
    reg [1:0] g_23_stage2, p_23_stage2;
    reg [3:0] g_stage2, p_stage2;
    reg       cin_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_01_stage2 <= 2'b0;
            p_01_stage2 <= 2'b0;
            g_23_stage2 <= 2'b0;
            p_23_stage2 <= 2'b0;
            g_stage2 <= 4'b0;
            p_stage2 <= 4'b0;
            cin_stage2 <= 1'b0;
        end else begin
            g_01_stage2 <= {g_stage1[1] | (p_stage1[1] & g_stage1[0]), g_stage1[0]};
            p_01_stage2 <= {p_stage1[1] & p_stage1[0], p_stage1[0]};
            g_23_stage2 <= {g_stage1[3] | (p_stage1[3] & g_stage1[2]), g_stage1[2]};
            p_23_stage2 <= {p_stage1[3] & p_stage1[0], p_stage1[2]};
            g_stage2 <= g_stage1;
            p_stage2 <= p_stage1;
            cin_stage2 <= cin_stage1;
        end
    end

    // Stage 3: Second level prefix computation
    reg g_03_stage3, p_03_stage3;
    reg [3:0] g_stage3, p_stage3;
    reg       cin_stage3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_03_stage3 <= 1'b0;
            p_03_stage3 <= 1'b0;
            g_stage3 <= 4'b0;
            p_stage3 <= 4'b0;
            cin_stage3 <= 1'b0;
        end else begin
            g_03_stage3 <= g_23_stage2[1] | (p_23_stage2[1] & g_01_stage2[1]);
            p_03_stage3 <= p_23_stage2[1] & p_01_stage2[1];
            g_stage3 <= g_stage2;
            p_stage3 <= p_stage2;
            cin_stage3 <= cin_stage2;
        end
    end

    // Stage 4: Carry and Sum computation
    reg [3:0] carry_stage4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage4 <= 4'b0;
            sum <= 4'b0;
            cout <= 1'b0;
        end else begin
            carry_stage4[0] <= cin_stage3;
            carry_stage4[1] <= g_stage3[0] | (p_stage3[0] & cin_stage3);
            carry_stage4[2] <= g_01_stage2[1] | (p_01_stage2[1] & cin_stage3);
            carry_stage4[3] <= g_03_stage3 | (p_03_stage3 & cin_stage3);
            
            sum <= p_stage3 ^ carry_stage4;
            cout <= carry_stage4[3];
        end
    end

endmodule