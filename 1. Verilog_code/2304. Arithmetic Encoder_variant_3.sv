//SystemVerilog
module arithmetic_encoder #(
    parameter PRECISION = 16
)(
    input                     clk,
    input                     rst,
    input                     symbol_valid,
    input              [7:0]  symbol,
    output reg                code_valid,
    output reg [PRECISION-1:0] lower_bound,
    output reg [PRECISION-1:0] upper_bound
);
    // Buffered probability table to reduce fan-out
    reg [PRECISION-1:0] prob_table [0:3];
    reg [PRECISION-1:0] prob_table_buf1 [0:3];
    reg [PRECISION-1:0] prob_table_buf2 [0:3];
    
    // Buffered lower bound registers
    reg [PRECISION-1:0] lower_bound_buf1;
    reg [PRECISION-1:0] lower_bound_buf2;
    
    reg [PRECISION-1:0] range;
    reg [PRECISION-1:0] range_buf;
    
    reg [1:0] symbol_msb;
    reg [1:0] symbol_msb_buf;
    
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
    end
    
    // Buffer stage for probability table
    always @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 4; i = i + 1) begin
                prob_table_buf1[i] <= prob_table[i];
                prob_table_buf2[i] <= prob_table[i];
            end
        end else begin
            for (integer i = 0; i < 4; i = i + 1) begin
                prob_table_buf1[i] <= prob_table[i];
                prob_table_buf2[i] <= prob_table[i];
            end
        end
    end
    
    // Register symbol MSBs to reduce timing path
    always @(posedge clk) begin
        symbol_msb <= symbol[7:6];
        symbol_msb_buf <= symbol_msb;
    end
    
    // Buffer stage for lower_bound
    always @(posedge clk) begin
        if (rst) begin
            lower_bound_buf1 <= 0;
            lower_bound_buf2 <= 0;
        end else begin
            lower_bound_buf1 <= lower_bound;
            lower_bound_buf2 <= lower_bound;
        end
    end
    
    // Buffer for range calculation
    always @(posedge clk) begin
        if (!rst && symbol_valid) begin
            range <= upper_bound - lower_bound + 1;
            range_buf <= range;
        end
    end
    
    // Main encoding logic with reduced fan-out
    always @(posedge clk) begin
        if (rst) begin
            lower_bound <= 0;
            upper_bound <= {PRECISION{1'b1}}; // All 1's
            code_valid <= 0;
        end else if (symbol_valid) begin
            // Calculate new bounds using buffered signals to reduce fan-out
            upper_bound <= lower_bound_buf1 + (range_buf * prob_table_buf1[symbol_msb+1])/PRECISION - 1;
            lower_bound <= lower_bound_buf2 + (range_buf * prob_table_buf2[symbol_msb])/PRECISION;
            
            code_valid <= 1;
        end else begin
            code_valid <= 0;
        end
    end
endmodule