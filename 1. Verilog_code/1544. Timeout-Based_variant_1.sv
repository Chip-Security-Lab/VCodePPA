//SystemVerilog
// IEEE 1364-2005
module timeout_shadow_reg #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 4
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    input  wire             data_valid,
    output reg  [WIDTH-1:0] shadow_out
);
    // Main data register
    reg [WIDTH-1:0] data_reg;
    
    // Timeout counter using optimal width
    reg [$clog2(TIMEOUT):0] timeout_cnt;
    
    // Flag for timeout detection
    wire timeout_trigger;
    
    // Main register reset logic
    always @(negedge rst_n) begin
        if (!rst_n)
            data_reg <= {WIDTH{1'b0}};
    end
    
    // Main register update logic
    always @(posedge clk) begin
        if (rst_n && data_valid)
            data_reg <= data_in;
    end
    
    // Timeout counter reset logic
    always @(negedge rst_n) begin
        if (!rst_n)
            timeout_cnt <= {($clog2(TIMEOUT)+1){1'b0}};
    end
    
    // Timeout counter update on data valid
    always @(posedge clk) begin
        if (rst_n && data_valid)
            timeout_cnt <= TIMEOUT;
    end
    
    // Timeout counter decrement logic
    always @(posedge clk) begin
        if (rst_n && !data_valid && |timeout_cnt)
            timeout_cnt <= timeout_cnt - 1'b1;
    end
    
    // Efficient timeout detection using equality comparison
    assign timeout_trigger = (timeout_cnt == 1'b1);
    
    // Shadow register reset logic
    always @(negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
    end
    
    // Shadow register update logic
    always @(posedge clk) begin
        if (rst_n && timeout_trigger)
            shadow_out <= data_reg;
    end
endmodule