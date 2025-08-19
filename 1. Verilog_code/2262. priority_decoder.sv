module priority_decoder(
    input [7:0] req_in,
    output reg [2:0] grant_addr,
    output reg valid
);
    always @(*) begin
        valid = 1'b0;
        grant_addr = 3'b000;
        if (req_in[7]) begin grant_addr = 3'b111; valid = 1'b1; end
        else if (req_in[6]) begin grant_addr = 3'b110; valid = 1'b1; end
        else if (req_in[5]) begin grant_addr = 3'b101; valid = 1'b1; end
        else if (req_in[4]) begin grant_addr = 3'b100; valid = 1'b1; end
        else if (req_in[3]) begin grant_addr = 3'b011; valid = 1'b1; end
        else if (req_in[2]) begin grant_addr = 3'b010; valid = 1'b1; end
        else if (req_in[1]) begin grant_addr = 3'b001; valid = 1'b1; end
        else if (req_in[0]) begin grant_addr = 3'b000; valid = 1'b1; end
    end
endmodule