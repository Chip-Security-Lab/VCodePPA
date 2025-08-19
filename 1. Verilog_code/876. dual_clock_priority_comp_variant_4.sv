//SystemVerilog
module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b
);

    // Stage 1: Register data_in for both domains
    reg [WIDTH-1:0] data_in_a_stage1;
    reg [WIDTH-1:0] data_in_b_stage1;

    // Stage 1 Registers for Domain A
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) data_in_a_stage1 <= 0;
        else data_in_a_stage1 <= data_in;
    end

    // Stage 1 Registers for Domain B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) data_in_b_stage1 <= 0;
        else data_in_b_stage1 <= data_in;
    end

    // Combinational priority logic function
    function [$clog2(WIDTH)-1:0] find_priority;
        input [WIDTH-1:0] data;
        integer k;
        begin
            find_priority = 0;
            for (k = WIDTH-1; k >= 0; k = k - 1)
                if (data[k]) find_priority = k[$clog2(WIDTH)-1:0];
        end
    endfunction

    // Stage 2: Priority calculation and output register for Domain A
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) priority_a <= 0;
        else priority_a <= find_priority(data_in_a_stage1);
    end

    // Stage 2: Priority calculation and output register for Domain B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) priority_b <= 0;
        else priority_b <= find_priority(data_in_b_stage1);
    end

endmodule