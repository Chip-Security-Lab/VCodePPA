//SystemVerilog
module sync_priority_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] temp_data;
    reg [ADDR_WIDTH-1:0] temp_addr;
    reg temp_we;

    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            temp_data <= 0;
            temp_addr <= 0;
            temp_we <= 0;
        end
    end

    // Write priority logic with optimized comparison
    always @(posedge clk) begin
        if (!rst) begin
            temp_we <= we_a | we_b;
            temp_data <= we_a ? din_a : din_b;
            temp_addr <= we_a ? addr_a : addr_b;
        end
    end

    // Memory write and output update
    always @(posedge clk) begin
        if (!rst && temp_we) begin
            ram[temp_addr] <= temp_data;
            dout <= temp_data;
        end
    end

endmodule