//SystemVerilog
module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b
);
    // Intermediate signals for priority calculation in Domain A
    wire [$clog2(WIDTH)-1:0] temp_priority_comb_a;

    // Pipelined registers for priority calculation in Domain A
    reg [$clog2(WIDTH)-1:0] priority_a_pipe1;

    // Intermediate signals for data synchronization and priority calculation in Domain B
    reg [WIDTH-1:0] sync_data_pipe1;
    wire [$clog2(WIDTH)-1:0] temp_priority_comb_b;

    // Pipelined registers for priority calculation in Domain B
    reg [$clog2(WIDTH)-1:0] priority_b_pipe1;


    // Combinational priority logic function
    function [$clog2(WIDTH)-1:0] find_priority_func;
        input [WIDTH-1:0] data;
        integer k;
        begin
            find_priority_func = 0;
            for (k = WIDTH-1; k >= 0; k = k - 1)
                if (data[k]) find_priority_func = k[$clog2(WIDTH)-1:0];
        end
    endfunction

    // Domain A - Combinational priority logic (Stage 1)
    // Finds the priority of data_in
    assign temp_priority_comb_a = find_priority_func(data_in);

    // Domain A - Pipelined Register (Stage 1)
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            priority_a_pipe1 <= 0;
        end else begin
            priority_a_pipe1 <= temp_priority_comb_a;
        end
    end

    // Domain A - Output Register (Stage 2)
    // Registers the priority of data_in in clock domain A
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            priority_a <= 0;
        end else begin
            priority_a <= priority_a_pipe1;
        end
    end

    // Domain B - Data Synchronization (Stage 1)
    // Synchronizes data_in from domain A to domain B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync_data_pipe1 <= 0;
        end else begin
            sync_data_pipe1 <= data_in;
        end
    end

    // Domain B - Combinational priority logic for synchronized data (Stage 2)
    // Finds the priority of the synchronized data
    assign temp_priority_comb_b = find_priority_func(sync_data_pipe1);

    // Domain B - Pipelined Register (Stage 2)
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_b_pipe1 <= 0;
        end else begin
            priority_b_pipe1 <= temp_priority_comb_b;
        end
    end

    // Domain B - Output Register (Stage 3)
    // Registers the priority of synchronized data in clock domain B
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            priority_b <= 0;
        end else begin
            priority_b <= priority_b_pipe1;
        end
    end

endmodule