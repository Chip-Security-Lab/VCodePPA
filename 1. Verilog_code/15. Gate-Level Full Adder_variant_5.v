module gate_level_adder_top(
    input clk,
    input rst_n,
    input a,
    input b,
    input cin,
    output reg sum,
    output reg cout
);

    // Stage 1: Input registers
    reg a_stage1, b_stage1, cin_stage1;
    
    // Stage 2: First XOR stage
    reg a_stage2, b_stage2, cin_stage2;
    wire s1_stage2;
    
    // Stage 3: Second XOR stage
    reg s1_stage3, cin_stage3;
    wire sum_stage3;
    
    // Stage 4: First carry stage
    reg a_stage4, b_stage4, s1_stage4, cin_stage4;
    wire c1_stage4;
    
    // Stage 5: Second carry stage
    reg s1_stage5, cin_stage5, c1_stage5;
    wire c2_stage5;
    
    // Stage 6: Final carry stage
    reg c1_stage6, c2_stage6;
    wire cout_stage6;

    // Stage 1: Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            cin_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            cin_stage1 <= cin;
        end
    end

    // Stage 2: First XOR stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
            cin_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            cin_stage2 <= cin_stage1;
        end
    end

    xor x1(s1_stage2, a_stage2, b_stage2);

    // Stage 3: Second XOR stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_stage3 <= 1'b0;
            cin_stage3 <= 1'b0;
        end else begin
            s1_stage3 <= s1_stage2;
            cin_stage3 <= cin_stage2;
        end
    end

    xor x2(sum_stage3, s1_stage3, cin_stage3);

    // Stage 4: First carry stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage4 <= 1'b0;
            b_stage4 <= 1'b0;
            s1_stage4 <= 1'b0;
            cin_stage4 <= 1'b0;
        end else begin
            a_stage4 <= a_stage2;
            b_stage4 <= b_stage2;
            s1_stage4 <= s1_stage2;
            cin_stage4 <= cin_stage2;
        end
    end

    and a1(c1_stage4, a_stage4, b_stage4);

    // Stage 5: Second carry stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_stage5 <= 1'b0;
            cin_stage5 <= 1'b0;
            c1_stage5 <= 1'b0;
        end else begin
            s1_stage5 <= s1_stage4;
            cin_stage5 <= cin_stage4;
            c1_stage5 <= c1_stage4;
        end
    end

    and a2(c2_stage5, s1_stage5, cin_stage5);

    // Stage 6: Final carry stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c1_stage6 <= 1'b0;
            c2_stage6 <= 1'b0;
        end else begin
            c1_stage6 <= c1_stage5;
            c2_stage6 <= c2_stage5;
        end
    end

    or o1(cout_stage6, c1_stage6, c2_stage6);

    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 1'b0;
            cout <= 1'b0;
        end else begin
            sum <= sum_stage3;
            cout <= cout_stage6;
        end
    end

endmodule