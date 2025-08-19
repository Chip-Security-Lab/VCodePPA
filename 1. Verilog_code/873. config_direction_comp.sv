module config_direction_comp #(parameter WIDTH = 8)(
    input clk, rst_n, 
    input direction,     // 0: MSB priority, 1: LSB priority
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= 0;
            if (direction) begin // LSB priority
                for (i = 0; i < WIDTH; i = i + 1)
                    if (data_in[i]) priority_out <= i[$clog2(WIDTH)-1:0];
            end else begin       // MSB priority
                for (i = WIDTH-1; i >= 0; i = i - 1)
                    if (data_in[i]) priority_out <= i[$clog2(WIDTH)-1:0];
            end
        end
    end
endmodule
