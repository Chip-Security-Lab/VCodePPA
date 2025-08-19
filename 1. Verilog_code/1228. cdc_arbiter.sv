module cdc_arbiter #(WIDTH=4) (
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] req_a,
    output [WIDTH-1:0] grant_b
);
    // Synchronization registers for CDC
    reg [WIDTH-1:0] sync0, sync1;
    reg [WIDTH-1:0] grant_b_reg;

    // Synchronize request from clk_a to clk_b domain
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync0 <= 0;
            sync1 <= 0;
        end else begin
            sync0 <= req_a;
            sync1 <= sync0;
        end
    end

    // Arbitration in clk_b domain - fixed priority
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            grant_b_reg <= 0;
        end else begin
            // Fixed priority arbitration: select lowest bit set
            grant_b_reg <= sync1 & (~sync1 + 1);
        end
    end

    assign grant_b = grant_b_reg;
endmodule