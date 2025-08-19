//SystemVerilog
module mult_direct #(parameter N=8) (
    input clk,
    input rst_n,
    input [N-1:0] a,
    input [N-1:0] b,
    output reg [2*N-1:0] prod
);

    // Pipeline registers
    reg [N-1:0] a_reg;
    reg [N-1:0] b_reg;
    
    // Split multiplication into partial products
    reg [N-1:0] a_part1, a_part2;
    reg [N-1:0] b_part1, b_part2;
    
    // Partial product results
    reg [N-0:0] partial_prod1;
    reg [N-0:0] partial_prod2;
    
    // Final product register
    reg [2*N-1:0] prod_reg;

    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Split operands into parts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_part1 <= {N{1'b0}};
            a_part2 <= {N{1'b0}};
            b_part1 <= {N{1'b0}};
            b_part2 <= {N{1'b0}};
        end else begin
            a_part1 <= a_reg[N-1:N/2];
            a_part2 <= a_reg[N/2-1:0];
            b_part1 <= b_reg[N-1:N/2];
            b_part2 <= b_reg[N/2-1:0];
        end
    end

    // Compute partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_prod1 <= {(N+1){1'b0}};
            partial_prod2 <= {(N+1){1'b0}};
        end else begin
            partial_prod1 <= a_part1 * b_part1;
            partial_prod2 <= a_part2 * b_part2;
        end
    end

    // Combine partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod_reg <= {(2*N){1'b0}};
        end else begin
            prod_reg <= (partial_prod1 << N) + (partial_prod2);
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod <= {(2*N){1'b0}};
        end else begin
            prod <= prod_reg;
        end
    end

endmodule