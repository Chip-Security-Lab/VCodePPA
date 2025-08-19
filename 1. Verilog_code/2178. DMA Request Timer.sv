module dma_timer #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period, threshold,
    output reg [WIDTH-1:0] count,
    output reg dma_req, period_match
);
    always @(posedge clk) begin
        if (rst) begin count <= {WIDTH{1'b0}}; period_match <= 1'b0; end
        else begin
            if (count == period - 1) begin
                count <= {WIDTH{1'b0}}; period_match <= 1'b1;
            end else begin count <= count + 1'b1; period_match <= 1'b0; end
        end
    end
    always @(posedge clk) begin
        if (rst) dma_req <= 1'b0;
        else dma_req <= (count == threshold - 1);
    end
endmodule