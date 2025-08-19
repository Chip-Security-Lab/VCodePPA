module priority_load_reg(
    input clk, rst_n,
    input [7:0] data_a, data_b, data_c,
    input load_a, load_b, load_c,
    output reg [7:0] result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 8'h00;
        else if (load_a)      // Highest priority
            result <= data_a;
        else if (load_b)      // Medium priority
            result <= data_b;
        else if (load_c)      // Lowest priority
            result <= data_c;
    end
endmodule