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
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 0;
        else if (data_valid)
            data_reg <= data_in;
    end
    
    // Timeout counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_cnt <= 0;
        end else if (data_valid) begin
            timeout_cnt <= TIMEOUT;
        end else if (timeout_cnt > 0) begin
            timeout_cnt <= timeout_cnt - 1;
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