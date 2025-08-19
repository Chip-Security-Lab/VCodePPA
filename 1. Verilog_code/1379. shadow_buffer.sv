module shadow_buffer (
    input wire clk,
    input wire [31:0] data_in,
    input wire capture,
    input wire update,
    output reg [31:0] data_out
);
    reg [31:0] shadow;
    
    always @(posedge clk) begin
        if (capture)
            shadow <= data_in;
        if (update)
            data_out <= shadow;
    end
endmodule