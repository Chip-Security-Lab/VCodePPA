module priority_encoder(
    input [7:0] req,
    output reg [2:0] code
);
    always @(*) begin
        if (req[7]) code = 3'b111;
        else if (req[6]) code = 3'b110;
        else if (req[5]) code = 3'b101;
        else if (req[4]) code = 3'b100;
        else if (req[3]) code = 3'b011;
        else if (req[2]) code = 3'b010;
        else if (req[1]) code = 3'b001;
        else code = 3'b000;
    end
endmodule