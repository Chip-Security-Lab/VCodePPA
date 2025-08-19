module rom_secure #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    input [4:0] addr,
    output reg [127:0] data
);
    reg [127:0] encrypted [0:31];
    
    // Initialize memory with some encrypted values
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            encrypted[i] = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h87654321} ^ {i, i, i, i};
    end
    
    always @(*) begin
        data = (key == KEY) ? encrypted[addr] : 128'h0;
    end
endmodule