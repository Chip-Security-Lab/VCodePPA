//SystemVerilog
module sync_ram_with_error_detection #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg error_flag
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] prev_dout;

    // RAM write operation
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
    end

    // RAM read operation
    always @(posedge clk) begin
        dout <= ram[addr];
    end

    // Previous output register
    always @(posedge clk) begin
        prev_dout <= dout;
    end

    // Error detection logic
    always @(posedge clk) begin
        error_flag <= (ram[addr] !== prev_dout) ? 1'b1 : error_flag;
    end

    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            prev_dout <= 0;
            error_flag <= 0;
        end
    end
endmodule