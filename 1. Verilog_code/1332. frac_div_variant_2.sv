//SystemVerilog
module frac_div #(parameter M=3, N=7) (
    input wire clk,
    input wire rst,
    output reg out
);

    // Combined accumulator pipeline
    reg [7:0] acc;
    reg valid;
    
    // Combinational logic for next accumulator value
    wire [7:0] next_acc = (acc >= N) ? (acc + M - N) : (acc + M);
    wire next_out = (next_acc >= N) ? 1'b1 : 1'b0;
    
    // Single-stage pipeline with forward-retimed registers
    always @(posedge clk) begin
        if (rst) begin
            acc <= 8'b0;
            valid <= 1'b0;
            out <= 1'b0;
        end
        else begin
            valid <= 1'b1;
            acc <= next_acc;
            if (valid) begin
                out <= next_out;
            end
        end
    end

endmodule