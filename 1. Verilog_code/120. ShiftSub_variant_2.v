module ShiftSub(input [7:0] a, b, output reg [7:0] res);
    reg [7:0] temp;
    reg [7:0] shifted_b;
    
    always @(*) begin
        res = a;
        temp = a;
        
        if (b == 8'b0) begin
            res = a;
        end else if (temp >= (b << 7)) begin
            temp = temp - (b << 7);
        end else if (temp >= (b << 6)) begin
            temp = temp - (b << 6);
        end else if (temp >= (b << 5)) begin
            temp = temp - (b << 5);
        end else if (temp >= (b << 4)) begin
            temp = temp - (b << 4);
        end else if (temp >= (b << 3)) begin
            temp = temp - (b << 3);
        end else if (temp >= (b << 2)) begin
            temp = temp - (b << 2);
        end else if (temp >= (b << 1)) begin
            temp = temp - (b << 1);
        end else if (temp >= b) begin
            temp = temp - b;
        end
        res = temp;
    end
endmodule