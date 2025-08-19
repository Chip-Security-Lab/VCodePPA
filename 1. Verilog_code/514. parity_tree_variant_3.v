module parity_tree(
    input [15:0] data,
    output even_par
);
    wire [7:0] level1;
    wire [3:0] level2;
    wire [1:0] level3;
    
    // First level reduction
    assign level1[0] = data[0] ^ data[1];
    assign level1[1] = data[2] ^ data[3];
    assign level1[2] = data[4] ^ data[5];
    assign level1[3] = data[6] ^ data[7];
    assign level1[4] = data[8] ^ data[9];
    assign level1[5] = data[10] ^ data[11];
    assign level1[6] = data[12] ^ data[13];
    assign level1[7] = data[14] ^ data[15];
    
    // Second level reduction
    assign level2[0] = level1[0] ^ level1[1];
    assign level2[1] = level1[2] ^ level1[3];
    assign level2[2] = level1[4] ^ level1[5];
    assign level2[3] = level1[6] ^ level1[7];
    
    // Third level reduction
    assign level3[0] = level2[0] ^ level2[1];
    assign level3[1] = level2[2] ^ level2[3];
    
    // Final XOR
    assign even_par = level3[0] ^ level3[1];
endmodule