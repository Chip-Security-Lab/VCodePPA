//SystemVerilog
// Top-level module
module fsm_div #(
    parameter EVEN = 4,
    parameter ODD = 5
)(
    input wire clk,
    input wire mode,
    input wire rst_n,
    output wire clk_out
);
    // Internal signals
    wire [2:0] state;
    wire state_reset;
    
    // Instantiate state counter submodule
    state_counter #(
        .EVEN(EVEN),
        .ODD(ODD)
    ) state_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .state(state),
        .state_reset(state_reset)
    );
    
    // Instantiate output generator submodule with LUT-based division
    output_generator_lut #(
        .EVEN(EVEN),
        .ODD(ODD)
    ) output_generator_inst (
        .mode(mode),
        .state(state),
        .clk_out(clk_out)
    );
    
endmodule

// State counter submodule
module state_counter #(
    parameter EVEN = 4,
    parameter ODD = 5
)(
    input wire clk,
    input wire rst_n,
    input wire mode,
    output reg [2:0] state,
    output wire state_reset
);
    // Determine when to reset the state counter
    assign state_reset = (mode) ? (state == ODD-1) : (state == EVEN-1);
    
    // State counter logic
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= 3'b000;
        end else begin
            state <= state_reset ? 3'b000 : state + 1'b1;
        end
    end
    
endmodule

// Output generator submodule with LUT-based division
module output_generator_lut #(
    parameter EVEN = 4,
    parameter ODD = 5
)(
    input wire mode,
    input wire [2:0] state,
    output reg clk_out
);
    // LUT for storing pre-computed EVEN/2 results (3-bit input)
    reg [7:0] even_div2_lut;
    // LUT for storing pre-computed ODD/2 results (3-bit input)
    reg [7:0] odd_div2_lut;
    
    // LUT threshold values
    wire [2:0] even_threshold;
    wire [2:0] odd_threshold;
    
    // Initialize LUTs with division results
    initial begin
        // Pre-computed EVEN/2 values for all possible 3-bit inputs
        even_div2_lut[0] = 3'd0;
        even_div2_lut[1] = 3'd0;
        even_div2_lut[2] = 3'd1;
        even_div2_lut[3] = 3'd1;
        even_div2_lut[4] = 3'd2;
        even_div2_lut[5] = 3'd2;
        even_div2_lut[6] = 3'd3;
        even_div2_lut[7] = 3'd3;
        
        // Pre-computed ODD/2 values for all possible 3-bit inputs
        odd_div2_lut[0] = 3'd0;
        odd_div2_lut[1] = 3'd0;
        odd_div2_lut[2] = 3'd1;
        odd_div2_lut[3] = 3'd1;
        odd_div2_lut[4] = 3'd2;
        odd_div2_lut[5] = 3'd2;
        odd_div2_lut[6] = 3'd3;
        odd_div2_lut[7] = 3'd3;
    end
    
    // Retrieve threshold values from LUTs
    assign even_threshold = even_div2_lut[EVEN[2:0]];
    assign odd_threshold = odd_div2_lut[ODD[2:0]];
    
    // Output generation logic using LUT-based division results
    always @(*) begin
        if (mode)
            clk_out = (state >= odd_threshold);
        else
            clk_out = (state >= even_threshold);
    end
    
endmodule