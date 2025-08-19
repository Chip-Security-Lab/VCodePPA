module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b
);
    wire [$clog2(WIDTH)-1:0] temp_priority;
    reg [WIDTH-1:0] sync_data;
    
    // Combinational priority logic
    function [$clog2(WIDTH)-1:0] find_priority;
        input [WIDTH-1:0] data;
        integer k;
        begin
            find_priority = 0;
            for (k = WIDTH-1; k >= 0; k = k - 1)
                if (data[k]) find_priority = k[$clog2(WIDTH)-1:0];
        end
    endfunction
    
    assign temp_priority = find_priority(data_in);
    
    // Domain A register
    always @(posedge clk_a or negedge rst_n)
        if (!rst_n) priority_a <= 0;
        else priority_a <= temp_priority;
    
    // Domain B - sync and register
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync_data <= 0;
            priority_b <= 0;
        end else begin
            sync_data <= data_in;
            priority_b <= find_priority(sync_data);
        end
    end
endmodule