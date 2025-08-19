module pipelined_adder (
    input wire clk,
    input wire rst_n,
    input wire [3:0] a,
    input wire [3:0] b,
    output reg [3:0] sum
);

    // Pipeline stage 1: Input registers
    reg [3:0] stage1_a;
    reg [3:0] stage1_b;
    
    // Pipeline stage 2: Manchester carry chain
    reg [3:0] stage2_sum;
    wire [3:0] p, g;
    wire [4:0] c;
    
    // Pipeline stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 4'b0;
            stage1_b <= 4'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end

    // Generate propagate and generate signals
    assign p = stage1_a ^ stage1_b;
    assign g = stage1_a & stage1_b;
    
    // Manchester carry chain
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // Pipeline stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_sum <= 4'b0;
        end else begin
            stage2_sum <= p ^ c[3:0];
        end
    end

    // Pipeline stage 3 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 4'b0;
        end else begin
            sum <= stage2_sum;
        end
    end

endmodule