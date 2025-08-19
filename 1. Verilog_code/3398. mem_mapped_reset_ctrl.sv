module mem_mapped_reset_ctrl(
    input wire clk,
    input wire [3:0] addr,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] reset_outputs
);
    always @(posedge clk) begin
        if (write_en) begin
            if (addr == 4'h0)
                reset_outputs <= data_in;
            else if (addr == 4'h1)
                reset_outputs <= reset_outputs | data_in;  // Set bits
            else if (addr == 4'h2)
                reset_outputs <= reset_outputs & ~data_in; // Clear bits
        end
    end
endmodule
