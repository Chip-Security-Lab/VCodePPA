//SystemVerilog
module wave10_lfsr #(
    parameter WIDTH = 8,
    parameter TAPS  = 8'hB8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // Pre-compute feedback term to reduce critical path
    reg feedback;
    
    always @(*) begin
        feedback = ^(wave_out & TAPS);
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= {WIDTH{1'b1}};
        end else begin
            wave_out <= {wave_out[WIDTH-2:0], feedback};
        end
    end
endmodule