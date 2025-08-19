module thermometer_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] thermometer_out,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermometer_out <= 0;
            priority_pos <= 0;
        end else begin
            // Find highest priority bit
            priority_pos <= 0;
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (data_in[i]) priority_pos <= i[$clog2(WIDTH)-1:0];
            
            // Generate thermometer code
            thermometer_out <= 0;
            for (integer j = 0; j < WIDTH; j = j + 1)
                if (j <= priority_pos) thermometer_out[j] <= 1;
                else thermometer_out[j] <= 0;
        end
    end
endmodule
