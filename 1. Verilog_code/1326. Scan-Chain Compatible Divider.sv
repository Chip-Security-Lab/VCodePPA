module scan_divider (
    input clk, rst_n, scan_en, scan_in,
    output reg clk_div,
    output scan_out
);
    reg [2:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'b000;
            clk_div <= 1'b0;
        end else if (scan_en) begin
            counter <= {counter[1:0], scan_in};
        end else if (counter == 3'b111) begin
            counter <= 3'b000;
            clk_div <= ~clk_div;
        end else
            counter <= counter + 1'b1;
    end
    
    assign scan_out = counter[2];
endmodule