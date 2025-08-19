module autoincrement_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write,
    input wire read,
    output reg [7:0] data_out
);
    reg [7:0] memory [0:15];
    reg [3:0] addr;
    
    always @(posedge clk) begin
        if (rst)
            addr <= 4'b0;
        else begin
            if (write) begin
                memory[addr] <= data_in;
                addr <= addr + 1;
            end
            if (read)
                data_out <= memory[addr];
        end
    end
endmodule