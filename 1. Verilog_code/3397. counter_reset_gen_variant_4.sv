//SystemVerilog
// SystemVerilog
module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    reg [3:0] counter;
    
    always @(posedge clk) begin
        case (enable)
            1'b0: counter <= 4'b0;
            1'b1: begin
                if (counter < THRESHOLD)
                    counter <= counter + 1'b1;
            end
        endcase
        
        // Optimized comparison with direct boolean assignment
        reset_out <= (counter == THRESHOLD);
    end
endmodule