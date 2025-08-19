module priority_decoder (
    input [3:0] request,
    output reg [1:0] grant,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        if (request[0]) grant = 2'b00;
        else if (request[1]) grant = 2'b01;
        else if (request[2]) grant = 2'b10;
        else if (request[3]) grant = 2'b11;
        else begin
            grant = 2'b00;
            valid = 1'b0;
        end
    end
endmodule