//SystemVerilog
//IEEE 1364-2005
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
    // Simplified probability model (fixed)
    reg [PRECISION-1:0] prob_table [0:3];
    reg [PRECISION-1:0] range, next_range;
    reg [1:0] symbol_msb;
    reg symbol_valid_d;
    reg [PRECISION-1:0] next_lower_bound, next_upper_bound;
    
    // Probability model initialization
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
    end
    
    // Capture input symbol and valid signal
    always @(posedge clk) begin
        if (rst) begin
            symbol_msb <= 2'b00;
            symbol_valid_d <= 1'b0;
        end else begin
            symbol_msb <= symbol_valid ? symbol[7:6] : symbol_msb;
            symbol_valid_d <= symbol_valid;
        end
    end
    
    // Calculate next range (combinational)
    always @(*) begin
        next_range = upper_bound - lower_bound + 1;
    end
    
    // Register range value
    always @(posedge clk) begin
        if (rst) begin
            range <= {PRECISION{1'b1}} + 1;  // Initialize to max range
        end else begin
            range <= next_range;
        end
    end
    
    // Bounds update logic (combinational)
    always @(*) begin
        if (symbol_valid_d) begin
            next_lower_bound = lower_bound + (range * prob_table[symbol_msb])/PRECISION;
            next_upper_bound = lower_bound + (range * prob_table[symbol_msb+1])/PRECISION - 1;
        end else begin
            next_lower_bound = lower_bound;
            next_upper_bound = upper_bound;
        end
    end
    
    // Register bound values
    always @(posedge clk) begin
        if (rst) begin
            lower_bound <= 0;
            upper_bound <= {PRECISION{1'b1}}; // All 1's
        end else begin
            lower_bound <= next_lower_bound;
            upper_bound <= next_upper_bound;
        end
    end
    
    // Output valid signal control
    always @(posedge clk) begin
        if (rst) begin
            code_valid <= 0;
        end else begin
            code_valid <= symbol_valid_d;
        end
    end
    
endmodule