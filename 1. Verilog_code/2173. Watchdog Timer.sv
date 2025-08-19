module watchdog_timer #(parameter WIDTH = 24)(
    input clk_i, rst_ni, wdt_en_i, feed_i,
    input [WIDTH-1:0] timeout_i,
    output reg timeout_o
);
    reg [WIDTH-1:0] counter;
    reg feed_d;
    wire feed_edge;
    always @(posedge clk_i) feed_d <= feed_i;
    assign feed_edge = feed_i & ~feed_d;
    always @(posedge clk_i) begin
        if (!rst_ni) begin counter <= {WIDTH{1'b0}}; timeout_o <= 1'b0; end
        else if (wdt_en_i) begin
            if (feed_edge) counter <= {WIDTH{1'b0}};
            else counter <= counter + 1'b1;
            if (counter >= timeout_i) timeout_o <= 1'b1;
        end
    end
endmodule