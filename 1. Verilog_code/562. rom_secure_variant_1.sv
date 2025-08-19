//SystemVerilog
module rom_secure #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    input [4:0] addr,
    output reg [127:0] data
);
    wire [127:0] encrypted_data;
    wire key_valid;

    // Instantiate the key checker module
    key_checker kc (
        .key(key),
        .key_valid(key_valid)
    );

    // Instantiate the memory module
    memory mem (
        .addr(addr),
        .encrypted_data(encrypted_data)
    );

    always @(*) begin
        if (key_valid) begin
            data = encrypted_data;
        end else begin
            data = 128'h0;
        end
    end
endmodule

module key_checker(
    input [31:0] key,
    output reg key_valid
);
    always @(*) begin
        if (key == 32'hA5A5A5A5) begin
            key_valid = 1'b1;
        end else begin
            key_valid = 1'b0;
        end
    end
endmodule

module memory(
    input [4:0] addr,
    output reg [127:0] encrypted_data
);
    reg [127:0] encrypted [0:31];

    // Initialize memory with some encrypted values
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            encrypted[i] = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h87654321} ^ {i, i, i, i};
    end

    always @(*) begin
        encrypted_data = encrypted[addr];
    end
endmodule