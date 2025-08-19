module power_on_reset_gen(
    input wire clk,
    input wire power_stable,
    output reg por_reset_n
);
    reg [2:0] por_counter;
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            por_counter <= 3'b0;
            por_reset_n <= 1'b0;
        end else if (por_counter < 3'b111) begin
            por_counter <= por_counter + 1'b1;
            por_reset_n <= 1'b0;
        end else
            por_reset_n <= 1'b1;
    end
endmodule