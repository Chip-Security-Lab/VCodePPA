//SystemVerilog
///////////////////////////////////////////////////////////
// Top-level module for shift register based divider
///////////////////////////////////////////////////////////
module shift_div #(
    parameter PATTERN = 8'b1010_1100
) (
    input  wire clk,     // System clock
    input  wire rst,     // Reset signal
    output wire clk_out  // Output clock
);

    // Internal connections between submodules
    wire [7:0] shift_data;
    // Buffered pattern parameter for reducing fanout
    reg [7:0] pattern_buf;
    // Buffered clock for distribution
    wire clk_buf1, clk_buf2;
    // Buffered shift data signals for load balancing
    reg [7:0] shift_data_buf1, shift_data_buf2;
    
    // Clock buffering for improved fanout handling
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    
    // Parameter buffering to reduce fanout
    always @(posedge clk_buf1 or posedge rst) begin
        if (rst)
            pattern_buf <= PATTERN;
        else
            pattern_buf <= pattern_buf;
    end
    
    // Shift data buffering for fanout reduction
    always @(posedge clk_buf1) begin
        shift_data_buf1 <= shift_data;
    end
    
    always @(posedge clk_buf2) begin
        shift_data_buf2 <= shift_data;
    end
    
    // Output extraction submodule instance
    output_extractor u_output_extractor (
        .shift_data (shift_data_buf1),
        .clk_out    (clk_out)
    );
    
    // Shift register core submodule instance
    shift_register_core #(
        .PATTERN    (PATTERN)
    ) u_shift_register_core (
        .clk        (clk_buf2),
        .rst        (rst),
        .pattern_buf(pattern_buf),
        .shift_data (shift_data)
    );

endmodule

///////////////////////////////////////////////////////////
// Shift register core - handles the shifting operation
///////////////////////////////////////////////////////////
module shift_register_core #(
    parameter PATTERN = 8'b1010_1100
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] pattern_buf,
    output reg  [7:0] shift_data
);

    // Implements the circular shift register function
    always @(posedge clk) begin
        if (rst) 
            shift_data <= pattern_buf; // Load buffered pattern on reset
        else 
            shift_data <= {shift_data[6:0], shift_data[7]}; // Circular shift
    end

endmodule

///////////////////////////////////////////////////////////
// Output extractor - extracts the output clock from shift register
///////////////////////////////////////////////////////////
module output_extractor (
    input  wire [7:0] shift_data,
    output reg        clk_out
);

    // Register output to reduce fanout impact on critical path
    always @(*) begin
        clk_out = shift_data[7];
    end

endmodule