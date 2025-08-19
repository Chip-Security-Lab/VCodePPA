//SystemVerilog
module dual_clock_priority_comp #(parameter WIDTH = 8)(
    input clk_a, clk_b, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_a,
    output reg [$clog2(WIDTH)-1:0] priority_b
);

    localparam ADDR_WIDTH = $clog2(WIDTH);

    // Combinational priority encoder function
    function [ADDR_WIDTH-1:0] priority_encoder;
        input [WIDTH-1:0] data;
        integer k;
        begin
            priority_encoder = 0;
            // Use 2's complement for decrementing loop counter
            // k = k - 1 is equivalent to k + (~1 + 1) = k + (~1) + 1
            // For constant -1, it's simpler: k = k + (-1)
            // Or, using 2's complement directly: k = k + {{(32-ADDR_WIDTH){1'b1}}, 1'b1}
            // However, standard integer loop is more readable and synthesized efficiently
            for (k = WIDTH-1; k >= 0; k = k - 1) begin
                if (data[k]) begin
                    priority_encoder = k[ADDR_WIDTH-1:0];
                    // Optimization: break loop once highest priority bit is found
                    // break; // SystemVerilog 'break' is not standard Verilog 2001, keep loop for compatibility
                end
            end
        end
    endfunction

    // Pipeline Stage 1: Priority encoding (Combinational)
    wire [ADDR_WIDTH-1:0] encoded_priority_comb = priority_encoder(data_in);

    // Clock Domain A Path
    // Stage 2a: Register priority in clk_a domain
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            priority_a <= 0;
        else
            priority_a <= encoded_priority_comb;
    end

    // Clock Domain B Path
    // Stage 2b: Synchronize data_in to clk_b domain
    reg [WIDTH-1:0] data_in_sync_b;
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            data_in_sync_b <= 0;
        else
            data_in_sync_b <= data_in;
    end

    // Stage 3b: Priority encode synchronized data in clk_b domain
    wire [ADDR_WIDTH-1:0] encoded_priority_sync_b_comb = priority_encoder(data_in_sync_b);

    // Stage 4b: Register priority in clk_b domain
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            priority_b <= 0;
        else
            priority_b <= encoded_priority_sync_b_comb;
    end

endmodule