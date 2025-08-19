module bin_reflected_gray_gen #(parameter WIDTH = 4) (
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] gray_code
);
    reg [WIDTH-1:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            gray_code <= {WIDTH{1'b0}};
        end else if (enable) begin
            counter <= counter + 1'b1;
            gray_code <= counter ^ (counter >> 1);
        end
    end
endmodule