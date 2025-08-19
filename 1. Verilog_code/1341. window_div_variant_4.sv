//SystemVerilog - IEEE 1364-2005
module window_div #(parameter L=5, H=12) (
    input wire clk, rst_n,
    input wire valid_in,     // Data valid input signal
    output wire valid_out,   // Data valid output signal
    output reg clk_out
);
    // Pipeline stage registers for counter
    reg [7:0] cnt;
    wire [7:0] cnt_next;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Kogge-Stone adder pipelined implementation
    kogge_stone_adder_pipelined #(.WIDTH(8)) adder (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .a(cnt),
        .b(8'd1),
        .sum(cnt_next),
        .valid_out(valid_stage1)
    );
    
    // Pipeline stage 2: Counter update and window comparison
    always @(posedge clk) begin
        if(!rst_n) begin
            cnt <= 0;
            clk_out <= 0;
            valid_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                cnt <= cnt_next;
                clk_out <= (cnt_next >= L) & (cnt_next <= H);
                valid_stage2 <= valid_stage1;
            end
        end
    end
    
    // Output valid signal
    assign valid_out = valid_stage2;
endmodule

module kogge_stone_adder_pipelined #(parameter WIDTH=8) (
    input wire clk, rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [WIDTH-1:0] sum,
    output reg valid_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] a_stage1, b_stage1;
    reg [WIDTH-1:0] p_stage0_reg, g_stage0_reg;
    reg [WIDTH-1:0] p_stage1_reg, g_stage1_reg;
    reg [WIDTH-1:0] p_stage2_reg, g_stage2_reg;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 0: Generate propagate and generate signals (combinational)
    wire [WIDTH-1:0] p_stage0, g_stage0;
    assign p_stage0 = a ^ b;
    assign g_stage0 = a & b;
    
    // Pipeline stage 1: Register input operands and stage 0 results
    always @(posedge clk) begin
        if (!rst_n) begin
            a_stage1 <= 0;
            b_stage1 <= 0;
            p_stage0_reg <= 0;
            g_stage0_reg <= 0;
            valid_stage1 <= 0;
        end else begin
            if (valid_in) begin
                a_stage1 <= a;
                b_stage1 <= b;
                p_stage0_reg <= p_stage0;
                g_stage0_reg <= g_stage0;
                valid_stage1 <= valid_in;
            end else begin
                valid_stage1 <= 0;
            end
        end
    end
    
    // Stage 1: Distance 1 (combinational)
    wire [WIDTH-1:0] p_stage1, g_stage1;
    assign p_stage1[0] = p_stage0_reg[0];
    assign g_stage1[0] = g_stage0_reg[0];
    
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : stage1_gen
            assign p_stage1[i] = p_stage0_reg[i] & p_stage0_reg[i-1];
            assign g_stage1[i] = g_stage0_reg[i] | (p_stage0_reg[i] & g_stage0_reg[i-1]);
        end
    endgenerate
    
    // Pipeline stage 2: Register stage 1 results
    always @(posedge clk) begin
        if (!rst_n) begin
            p_stage1_reg <= 0;
            g_stage1_reg <= 0;
            valid_stage2 <= 0;
        end else begin
            if (valid_stage1) begin
                p_stage1_reg <= p_stage1;
                g_stage1_reg <= g_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 0;
            end
        end
    end
    
    // Stage 2: Distance 2 (combinational)
    wire [WIDTH-1:0] p_stage2, g_stage2;
    assign p_stage2[0] = p_stage1_reg[0];
    assign g_stage2[0] = g_stage1_reg[0];
    assign p_stage2[1] = p_stage1_reg[1];
    assign g_stage2[1] = g_stage1_reg[1];
    
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : stage2_gen
            assign p_stage2[i] = p_stage1_reg[i] & p_stage1_reg[i-2];
            assign g_stage2[i] = g_stage1_reg[i] | (p_stage1_reg[i] & g_stage1_reg[i-2]);
        end
    endgenerate
    
    // Pipeline stage 3: Register stage 2 results
    always @(posedge clk) begin
        if (!rst_n) begin
            p_stage2_reg <= 0;
            g_stage2_reg <= 0;
            valid_stage3 <= 0;
        end else begin
            if (valid_stage2) begin
                p_stage2_reg <= p_stage2;
                g_stage2_reg <= g_stage2;
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 0;
            end
        end
    end
    
    // Stage 3: Distance 4 (combinational)
    wire [WIDTH-1:0] p_stage3, g_stage3;
    
    generate
        for (i = 0; i < 4 && i < WIDTH; i = i + 1) begin : stage3_gen_lower
            assign p_stage3[i] = p_stage2_reg[i];
            assign g_stage3[i] = g_stage2_reg[i];
        end
    endgenerate
    
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin : stage3_gen_upper
            assign p_stage3[i] = p_stage2_reg[i] & p_stage2_reg[i-4];
            assign g_stage3[i] = g_stage2_reg[i] | (p_stage2_reg[i] & g_stage2_reg[i-4]);
        end
    endgenerate
    
    // Calculate carry bits
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0; // No carry-in
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry[i+1] = g_stage3[i] | (p_stage3[i] & carry[i]);
        end
    endgenerate
    
    // Pipeline stage 4: Calculate and register final sum
    always @(posedge clk) begin
        if (!rst_n) begin
            sum <= 0;
            valid_out <= 0;
        end else begin
            if (valid_stage3) begin
                sum <= p_stage0_reg ^ carry[WIDTH-1:0];
                valid_out <= valid_stage3;
            end else begin
                valid_out <= 0;
            end
        end
    end
endmodule