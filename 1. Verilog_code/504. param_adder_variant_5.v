module param_adder #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [WIDTH:0] sum
);

    // Stage 1 signals
    reg [WIDTH-1:0] a_stage1;
    reg [WIDTH-1:0] b_stage1;
    wire [WIDTH-1:0] p_stage1;
    wire [WIDTH-1:0] g_stage1;
    
    // Stage 2 signals
    reg [WIDTH-1:0] p_stage2;
    reg [WIDTH-1:0] g_stage2;
    wire [WIDTH:0] carry_stage2;
    
    // Stage 3 signals
    reg [WIDTH:0] carry_stage3;
    reg [WIDTH-1:0] p_stage3;
    wire [WIDTH:0] sum_stage3;
    
    // Stage 1: Input register and PG generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= {WIDTH{1'b0}};
            b_stage1 <= {WIDTH{1'b0}};
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg_stage1
            assign p_stage1[i] = a_stage1[i] ^ b_stage1[i];
            assign g_stage1[i] = a_stage1[i] & b_stage1[i];
        end
    endgenerate
    
    // Stage 2: PG register and carry computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage2 <= {WIDTH{1'b0}};
            g_stage2 <= {WIDTH{1'b0}};
        end else begin
            p_stage2 <= p_stage1;
            g_stage2 <= g_stage1;
        end
    end
    
    assign carry_stage2[0] = 1'b0;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry_stage2
            assign carry_stage2[i+1] = g_stage2[i] | (p_stage2[i] & carry_stage2[i]);
        end
    endgenerate
    
    // Stage 3: Carry register and sum computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage3 <= {(WIDTH+1){1'b0}};
            p_stage3 <= {WIDTH{1'b0}};
        end else begin
            carry_stage3 <= carry_stage2;
            p_stage3 <= p_stage2;
        end
    end
    
    assign sum_stage3[WIDTH] = carry_stage3[WIDTH];
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum_stage3
            assign sum_stage3[i] = p_stage3[i] ^ carry_stage3[i];
        end
    endgenerate
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= {(WIDTH+1){1'b0}};
        end else begin
            sum <= sum_stage3;
        end
    end

endmodule