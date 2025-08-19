//SystemVerilog
module int_ctrl_software #(
    parameter WIDTH = 8
)(
    input  wire                clk,     // System clock
    input  wire                wr_en,   // Write enable signal
    input  wire [WIDTH-1:0]    sw_int,  // Software interrupt input
    output reg  [WIDTH-1:0]    int_out  // Interrupt output signals
);

    // Optimized pipeline structure with fewer registers
    reg                 wr_en_pipe;
    reg [WIDTH-1:0]     sw_int_pipe;
    
    // Single-stage pipeline for control signals
    always @(posedge clk) begin
        wr_en_pipe <= wr_en;
        sw_int_pipe <= sw_int;
    end
    
    // Optimized output generation with enable-based assignment
    always @(posedge clk) begin
        int_out <= wr_en_pipe ? sw_int_pipe : {WIDTH{1'b0}};
    end

endmodule