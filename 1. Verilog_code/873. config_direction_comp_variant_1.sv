//SystemVerilog
module config_direction_comp #(parameter WIDTH = 8)(
    input clk, rst_n, 
    input direction,     // 0: MSB priority, 1: LSB priority
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);

    reg [$clog2(WIDTH)-1:0] priority_reg;
    reg [WIDTH-1:0] data_reg;
    reg direction_reg;
    integer i;

    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
            direction_reg <= 0;
        end else begin
            data_reg <= data_in;
            direction_reg <= direction;
        end
    end

    // Pipeline stage 2: Priority calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_reg <= 0;
        end else begin
            priority_reg <= 0;
            if (direction_reg) begin // LSB priority
                for (i = 0; i < WIDTH; i = i + 1)
                    if (data_reg[i]) priority_reg <= i[$clog2(WIDTH)-1:0];
            end else begin       // MSB priority
                for (i = WIDTH-1; i >= 0; i = i - 1)
                    if (data_reg[i]) priority_reg <= i[$clog2(WIDTH)-1:0];
            end
        end
    end

    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= priority_reg;
        end
    end

endmodule