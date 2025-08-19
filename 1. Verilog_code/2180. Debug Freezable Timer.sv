module debug_timer #(parameter WIDTH = 16)(
    input wire clk, rst_n, enable, debug_mode,
    input wire [WIDTH-1:0] reload,
    output reg [WIDTH-1:0] count,
    output wire expired
);
    reg reload_pending;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin count <= {WIDTH{1'b0}}; reload_pending <= 1'b0; end
        else if (enable && !debug_mode) begin
            if (count == {WIDTH{1'b1}} || reload_pending) begin
                count <= reload; reload_pending <= 1'b0;
            end else begin count <= count + 1'b1; end
        end else if (debug_mode && count == {WIDTH{1'b1}}) begin
            reload_pending <= 1'b1;
        end
    end
    assign expired = (count == {WIDTH{1'b1}}) && enable && !debug_mode;
endmodule