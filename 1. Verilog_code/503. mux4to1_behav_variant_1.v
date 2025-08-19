module mux4to1_booth(
    input [3:0] data,
    input [1:0] sel,
    output reg y
);

    // Booth encoding for selection
    wire [2:0] booth_enc;
    reg [3:0] booth_prod;
    reg [3:0] booth_result;
    
    // Booth encoder
    assign booth_enc[0] = sel[0];
    assign booth_enc[1] = sel[1] ^ sel[0];
    assign booth_enc[2] = sel[1] & sel[0];
    
    // Booth multiplier implementation
    always @(*) begin
        booth_prod = 4'b0;
        
        // Booth multiplication
        if (booth_enc[0]) booth_prod = booth_prod + data;
        if (booth_enc[1]) booth_prod = booth_prod + {data[2:0], 1'b0};
        if (booth_enc[2]) booth_prod = booth_prod + {data[1:0], 2'b0};
        
        // Final selection based on Booth result
        booth_result = booth_prod & 4'b0001;
        y = |booth_result;
    end

endmodule