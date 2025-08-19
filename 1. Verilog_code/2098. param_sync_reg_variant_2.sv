//SystemVerilog
module param_sync_reg #(parameter WIDTH=4) (
    input clk1, clk2, rst,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] din_reg;
    reg [WIDTH-1:0] sync_reg;

    always @(posedge clk1 or posedge rst) begin
        if (rst)
            din_reg <= {WIDTH{1'b0}};
        else
            din_reg <= din;
    end

    always @(posedge clk2 or posedge rst) begin
        if (rst)
            sync_reg <= {WIDTH{1'b0}};
        else
            sync_reg <= din_reg;
    end

    assign dout = sync_reg;

endmodule