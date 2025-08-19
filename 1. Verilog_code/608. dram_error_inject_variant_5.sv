//SystemVerilog
module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input wire clk,
    input wire enable,
    input wire [63:0] data_in,
    output reg [63:0] data_out
);

    // Pipeline registers
    reg [63:0] data_pipe;
    reg enable_pipe;
    
    // Error mask generation
    wire [63:0] error_pattern = {8{ERROR_MASK}};
    
    // Pipeline stage 1: Input registration
    always @(posedge clk) begin
        data_pipe <= data_in;
        enable_pipe <= enable;
    end
    
    // Pipeline stage 2: Error injection
    always @(posedge clk) begin
        if (enable_pipe) begin
            data_out <= data_pipe ^ error_pattern;
        end else begin
            data_out <= data_pipe;
        end
    end

endmodule