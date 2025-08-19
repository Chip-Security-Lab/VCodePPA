//SystemVerilog
// IEEE 1364-2005 Verilog Standard
module timeout_shadow_reg #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire data_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Timeout counter
    reg [$clog2(TIMEOUT)-1:0] timeout_cnt;
    reg [$clog2(TIMEOUT)-1:0] next_timeout_cnt;
    
    // Carry lookahead borrow signals
    wire [$clog2(TIMEOUT)-1:0] gen_borrow;
    wire [$clog2(TIMEOUT)-1:0] prop_borrow;
    wire [$clog2(TIMEOUT)-1:0] actual_borrow;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 0;
        else if (data_valid)
            data_reg <= data_in;
    end
    
    // Generate borrow signals for carry lookahead subtraction
    assign gen_borrow[0] = (timeout_cnt[0] == 1'b0);
    assign prop_borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 1; i < $clog2(TIMEOUT); i = i + 1) begin : borrow_gen
            assign gen_borrow[i] = (timeout_cnt[i] == 1'b0);
            assign prop_borrow[i] = (timeout_cnt[i] == 1'b0) | (timeout_cnt[i-1:0] == 0);
        end
    endgenerate
    
    // Calculate actual borrow signals
    assign actual_borrow[0] = gen_borrow[0];
    
    generate
        for (i = 1; i < $clog2(TIMEOUT); i = i + 1) begin : borrow_prop
            assign actual_borrow[i] = gen_borrow[i] | (prop_borrow[i] & actual_borrow[i-1]);
        end
    endgenerate
    
    // Lookahead borrow subtractor implementation
    always @(*) begin
        if (data_valid) begin
            next_timeout_cnt = TIMEOUT;
        end else if (timeout_cnt > 0) begin
            next_timeout_cnt[0] = timeout_cnt[0] ^ 1'b1;
            for (int j = 1; j < $clog2(TIMEOUT); j = j + 1) begin
                next_timeout_cnt[j] = timeout_cnt[j] ^ actual_borrow[j-1];
            end
        end else begin
            next_timeout_cnt = 0;
        end
    end
    
    // Timeout counter update with lookahead borrow implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_cnt <= 0;
        end else begin
            timeout_cnt <= next_timeout_cnt;
        end
    end
    
    // Shadow register update when timeout occurs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else if (timeout_cnt == 1)
            shadow_out <= data_reg;
    end
endmodule