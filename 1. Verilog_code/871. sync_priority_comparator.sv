module sync_priority_comparator #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid <= 0;
        end else begin
            valid <= |data_in;
            priority_out <= 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (data_in[i]) 
                    priority_out <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule