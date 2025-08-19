//SystemVerilog
module mux_divider (
    input main_clock, reset, enable,
    input [1:0] select,
    output out_clock
);
    reg [3:0] divider;
    reg [3:0] dividend, divisor;
    reg [3:0] quotient, remainder;
    reg [2:0] count;
    reg division_active;
    wire div2, div4, div8, div16;
    
    // Binary long division implementation
    always @(posedge main_clock or posedge reset) begin
        if (reset) begin
            divider <= 4'b0000;
            dividend <= 4'b0000;
            divisor <= 4'b0010; // Divisor = 2
            quotient <= 4'b0000;
            remainder <= 4'b0000;
            count <= 3'b000;
            division_active <= 1'b0;
        end
        else if (enable) begin
            if (!division_active) begin
                dividend <= divider + 1'b1;
                divisor <= 4'b0010; // Fixed divisor for this implementation
                quotient <= 4'b0000;
                remainder <= 4'b0000;
                count <= 3'b100; // Start from MSB (4 bits)
                division_active <= 1'b1;
            end
            else if (count > 0) begin
                // Shift remainder and bring down next bit from dividend
                remainder <= {remainder[2:0], dividend[count-1]};
                
                // Check if remainder >= divisor
                if ({remainder[2:0], dividend[count-1]} >= divisor) begin
                    remainder <= {remainder[2:0], dividend[count-1]} - divisor;
                    quotient[count-1] <= 1'b1;
                end
                else begin
                    quotient[count-1] <= 1'b0;
                end
                
                count <= count - 1'b1;
            end
            else begin
                divider <= quotient;
                division_active <= 1'b0;
            end
        end
    end
    
    assign div2 = divider[0];
    assign div4 = divider[1];
    assign div8 = divider[2];
    assign div16 = divider[3];
    
    assign out_clock = (select == 2'b00) ? div2 :
                       (select == 2'b01) ? div4 :
                       (select == 2'b10) ? div8 : div16;
endmodule