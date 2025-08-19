//SystemVerilog
module GoldschmidtDivider(
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    input valid,
    output reg ready
);

    reg [7:0] x, y;
    reg [15:0] x_ext, y_ext;
    reg [7:0] f;
    reg [15:0] temp;
    integer i;

    always @(posedge valid or negedge valid) begin
        if (valid) begin
            ready = 0; // Initially not ready
            if (divisor == 0) begin
                quotient = 8'hFF;
                ready = 1; // Ready after processing
            end else begin
                x = dividend;
                y = divisor;
                x_ext = {8'b0, x};
                y_ext = {8'b0, y};
                
                // Initial approximation
                f = 8'hFF - y;
                
                // Iteration 1
                x_ext = x_ext * f;
                y_ext = y_ext * f;
                x_ext = x_ext >> 8;
                y_ext = y_ext >> 8;
                
                // Iteration 2
                f = 8'hFF - y_ext[7:0];
                x_ext = x_ext * f;
                y_ext = y_ext * f;
                x_ext = x_ext >> 8;
                
                quotient = x_ext[7:0];
                ready = 1; // Ready after processing
            end
        end
    end
endmodule

module SatDiv(
    input [7:0] a, b,
    input valid,
    output reg [7:0] q,
    output reg ready
);
    GoldschmidtDivider divider(
        .dividend(a),
        .divisor(b),
        .quotient(q),
        .valid(valid),
        .ready(ready)
    );
endmodule