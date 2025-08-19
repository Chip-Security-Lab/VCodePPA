//SystemVerilog
module multiplier_hardware (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

    wire [7:0][15:0] shifted_b;
    wire [7:0] selected;
    
    // Barrel shifter implementation using multiplexers
    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin: gen_shift
            assign shifted_b[i] = {8'b0, b} << i;
            assign selected[i] = a[i];
        end
    endgenerate

    // Product calculation using barrel shifter outputs
    always @(*) begin
        product = 0;
        for(int j = 0; j < 8; j = j + 1) begin
            if(selected[j]) begin
                product = product + shifted_b[j];
            end
        end
    end

endmodule