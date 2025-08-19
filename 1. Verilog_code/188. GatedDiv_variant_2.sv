//SystemVerilog
module GatedDiv(
    input clk,
    input en,
    input [15:0] x, 
    input [15:0] y,
    output reg [15:0] q,
    output reg valid,
    input ready
);
    reg [15:0] remainder;
    reg [15:0] divisor;
    reg [15:0] quotient;
    reg [4:0] count; // To keep track of the number of shifts

    always @(posedge clk) begin
        if (en) begin
            if (valid && ready) begin
                q <= quotient;
                valid <= 0; // Clear valid after data is sent
            end else if (!valid) begin
                if (y != 0) begin
                    remainder <= x; // Initialize remainder with x
                    divisor <= y;   // Initialize divisor with y
                    quotient <= 0;  // Reset quotient
                    count <= 16;    // Set the count to the width of the data
                end else begin
                    quotient <= 16'hFFFF; // Division by zero case
                    valid <= 1; // Set valid when data is ready
                end
            end else if (count > 0) begin
                // Shift left the quotient
                quotient <= {quotient[14:0], 1'b0};
                remainder <= {remainder[14:0], 1'b0}; // Shift remainder left
                remainder[0] <= divisor[0]; // Bring in the next bit of the divisor

                if (remainder >= divisor) begin
                    remainder <= remainder - divisor; // Subtract divisor from remainder
                    quotient[0] <= 1; // Set the least significant bit of quotient
                end
                count <= count - 1; // Decrement the count
            end else begin
                valid <= 1; // Set valid when division is complete
            end
        end
    end
endmodule