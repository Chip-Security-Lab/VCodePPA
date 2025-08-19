module johnson_counter #(parameter WIDTH = 4) (
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] johnson_code
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            johnson_code <= {WIDTH{1'b0}};
        else if (enable)
            johnson_code <= {~johnson_code[0], johnson_code[WIDTH-1:1]};
    end
endmodule