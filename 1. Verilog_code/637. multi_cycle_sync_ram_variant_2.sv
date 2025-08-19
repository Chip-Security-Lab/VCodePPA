//SystemVerilog
module multi_cycle_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter CYCLE_COUNT = 3
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [1:0] cycle_counter;
    reg [DATA_WIDTH-1:0] data_reg;
    wire cycle_done;

    assign cycle_done = (cycle_counter == CYCLE_COUNT-1);

    // RAM write control
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
    end

    // Cycle counter control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter <= 0;
        end else begin
            if (we || cycle_done) begin
                cycle_counter <= 0;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

    // Data register control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 0;
        end else begin
            if (we) begin
                data_reg <= din;
            end else if (!cycle_done) begin
                data_reg <= ram[addr];
            end
        end
    end

    // Output control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (cycle_done) begin
            dout <= data_reg;
        end
    end

endmodule