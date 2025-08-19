//SystemVerilog
module priority_decoder(
    input [7:0] req_in,
    output reg [2:0] grant_addr,
    output reg valid
);
    
    always @(*) begin
        // Default values
        grant_addr = 3'b000;
        
        // Optimized priority encoder using casez
        casez(req_in)
            8'b1???????: grant_addr = 3'b111;
            8'b01??????: grant_addr = 3'b110;
            8'b001?????: grant_addr = 3'b101;
            8'b0001????: grant_addr = 3'b100;
            8'b00001???: grant_addr = 3'b011;
            8'b000001??: grant_addr = 3'b010;
            8'b0000001?: grant_addr = 3'b001;
            8'b00000001: grant_addr = 3'b000;
            default:     grant_addr = 3'b000;
        endcase
        
        // Direct assignment for valid signal
        valid = |req_in;
    end
endmodule