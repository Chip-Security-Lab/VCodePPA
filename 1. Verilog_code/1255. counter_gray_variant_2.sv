//SystemVerilog
module counter_gray #(parameter BITS=4) (
    input clk, rst_n, en,
    output reg [BITS-1:0] gray
);
    // Binary counter with direct gray code conversion
    reg [BITS-1:0] bin_counter;
    wire [BITS-1:0] gray_next;
    
    // Combinational gray code conversion
    assign gray_next = bin_counter ^ (bin_counter >> 1);
    
    // Binary counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_counter <= {BITS{1'b0}};
            gray <= {BITS{1'b0}};
        end else if (en) begin
            bin_counter <= bin_counter + 1'b1;
            gray <= gray_next;
        end
    end
endmodule