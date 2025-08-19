//SystemVerilog
module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire [REQ_WIDTH-1:0] request,
    output wire [REQ_WIDTH-1:0] grant
);
    wire [REQ_WIDTH-1:0] next_grant;
    reg [REQ_WIDTH-1:0] grant_reg;

    // Optimized priority encoder using parallel prefix computation
    assign next_grant = request & (~(request - 1'b1));

    // Optimized register stage with synchronous reset
    always @(posedge clk) begin
        if (!rst_n)
            grant_reg <= {REQ_WIDTH{1'b0}};
        else
            grant_reg <= next_grant;
    end

    assign grant = grant_reg;
endmodule