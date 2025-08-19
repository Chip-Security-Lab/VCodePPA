//SystemVerilog
module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b
);
    wire [$clog2(WIDTH)-1:0] temp_priority_a;
    wire [$clog2(WIDTH)-1:0] temp_priority_b;

    reg [WIDTH-1:0] data_in_reg_b;

    // Combinational priority logic using optimized comparison
    function [$clog2(WIDTH)-1:0] find_priority_optimized;
        input [WIDTH-1:0] data;
        reg [$clog2(WIDTH)-1:0] pri;
        integer i;
        begin
            pri = 0; // Default to 0 if no bits are set
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (data[i]) begin
                    pri = i[$clog2(WIDTH)-1:0];
                end
            end
            find_priority_optimized = pri;
        end
    endfunction

    // Combinational logic for domain A
    assign temp_priority_a = find_priority_optimized(data_in);

    // Domain A register
    always @(posedge clk_a or negedge rst_n)
        if (!rst_n) priority_a <= 0;
        else priority_a <= temp_priority_a;

    // Domain B - register data_in first, then find priority
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg_b <= 0;
        end else begin
            data_in_reg_b <= data_in;
        end
    end

    // Combinational logic for domain B
    assign temp_priority_b = find_priority_optimized(data_in_reg_b);

    // Domain B register
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_b <= 0;
        end else begin
            priority_b <= temp_priority_b;
        end
    end
endmodule