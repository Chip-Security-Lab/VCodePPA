module ifelse_mux (
    input wire control,           // Control signal
    input wire [3:0] path_a, path_b, // Data paths
    output reg [3:0] selected     // Output data path
);
    always @(*) begin
        if (control == 1'b0)
            selected = path_a;    // Select path A
        else
            selected = path_b;    // Select path B
    end
endmodule