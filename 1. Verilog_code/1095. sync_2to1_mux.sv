module sync_2to1_mux (
    input wire clk,               // Clock signal
    input wire [7:0] data_a, data_b, // Data inputs
    input wire sel,               // Selection bit
    output reg [7:0] q_out        // Registered output
);
    always @(posedge clk) begin
        q_out <= sel ? data_b : data_a;
    end
endmodule