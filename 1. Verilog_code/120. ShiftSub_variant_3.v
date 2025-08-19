module ShiftSub(input [7:0] a, b, output reg [7:0] res);
    wire [7:0] shifted_b [7:0];
    wire [7:0] sub_res [7:0];
    reg [7:0] temp_res;
    integer i;
    
    // Optimized barrel shifter using power-of-2 shifts
    assign shifted_b[0] = b;
    assign shifted_b[1] = b << 1;
    assign shifted_b[2] = b << 2;
    assign shifted_b[3] = b << 3;
    assign shifted_b[4] = b << 4;
    assign shifted_b[5] = b << 5;
    assign shifted_b[6] = b << 6;
    assign shifted_b[7] = b << 7;
    
    // Parallel subtraction with optimized comparison
    generate
        genvar j;
        for(j=0; j<8; j=j+1) begin : sub_units
            assign sub_res[j] = temp_res - shifted_b[j];
        end
    endgenerate
    
    // Optimized comparison chain using priority encoding
    always @(*) begin
        temp_res = a;
        for(i=7; i>=0; i=i-1) begin
            if(temp_res >= shifted_b[i]) begin
                temp_res = sub_res[i];
            end
        end
        res = temp_res;
    end
endmodule