//SystemVerilog
module decoder_arbiter #(NUM_MASTERS=2) (
    input [NUM_MASTERS-1:0] req,
    output reg [NUM_MASTERS-1:0] grant
);
    // Internal signals for borrow subtractor
    reg [NUM_MASTERS-1:0] borrow;
    reg [NUM_MASTERS-1:0] diff;
    reg [NUM_MASTERS-1:0] mask;
    
    always @* begin
        // Initialize borrow
        borrow[0] = 1'b1;
        
        // Borrow subtractor implementation
        for(int i=0; i<NUM_MASTERS; i++) begin
            if(i > 0) begin
                borrow[i] = ~req[i-1] & borrow[i-1];
            end
            diff[i] = req[i] ^ borrow[i];
        end
        
        // Create mask by ANDing with original request
        mask = req & diff;
        
        // Assign grant using the mask
        grant = mask;
    end
endmodule