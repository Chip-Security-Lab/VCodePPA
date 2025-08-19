//SystemVerilog
module AsyncResetOR(
    input rst_n,
    input [3:0] d1, d2,
    output reg [7:0] q
);
    reg [7:0] product;
    reg [7:0] shifted_d1;
    reg [3:0] i;
    
    always @(*) begin
        product = 8'b0;
        shifted_d1 = {4'b0, d1};
        i = 4'b0;
        
        if (!rst_n) begin
            q = 4'b1111;
        end else if (rst_n && d2[0]) begin
            product = product + shifted_d1;
            i = 4'b0001;
        end else if (rst_n && !d2[0]) begin
            i = 4'b0001;
        end
        
        if (rst_n && i == 4'b0001 && d2[1]) begin
            product = product + (shifted_d1 << 1);
            i = 4'b0010;
        end else if (rst_n && i == 4'b0001 && !d2[1]) begin
            i = 4'b0010;
        end
        
        if (rst_n && i == 4'b0010 && d2[2]) begin
            product = product + (shifted_d1 << 2);
            i = 4'b0011;
        end else if (rst_n && i == 4'b0010 && !d2[2]) begin
            i = 4'b0011;
        end
        
        if (rst_n && i == 4'b0011 && d2[3]) begin
            product = product + (shifted_d1 << 3);
            i = 4'b0100;
        end else if (rst_n && i == 4'b0011 && !d2[3]) begin
            i = 4'b0100;
        end
        
        if (rst_n) begin
            q = product;
        end
    end
endmodule