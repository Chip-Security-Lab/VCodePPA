//SystemVerilog
module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout_a, next_dout_b;
    reg [DATA_WIDTH-1:0] next_ram_a, next_ram_b;
    reg write_a, write_b;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [DATA_WIDTH-1:0] ram_data_a_next, ram_data_b_next;

    // Write enable logic
    always @(*) begin
        write_a = we_a && !rst;
        write_b = we_b && !rst;
    end

    // RAM read logic
    always @(*) begin
        ram_data_a = ram[addr_a];
        ram_data_b = ram[addr_b];
    end

    // Next RAM data logic
    always @(*) begin
        ram_data_a_next = write_a ? din_a : ram_data_a;
        ram_data_b_next = write_b ? din_b : ram_data_b;
    end

    // Output and RAM update logic
    always @(*) begin
        if (rst) begin
            next_dout_a = 0;
            next_dout_b = 0;
            next_ram_a = ram_data_a;
            next_ram_b = ram_data_b;
        end else if (read_first) begin
            next_dout_a = ram_data_a;
            next_dout_b = ram_data_b;
            next_ram_a = ram_data_a_next;
            next_ram_b = ram_data_b_next;
        end else begin
            next_ram_a = ram_data_a_next;
            next_ram_b = ram_data_b_next;
            next_dout_a = ram_data_a;
            next_dout_b = ram_data_b;
        end
    end

    // Clocked logic
    always @(posedge clk) begin
        dout_a <= next_dout_a;
        dout_b <= next_dout_b;
        if (write_a) ram[addr_a] <= next_ram_a;
        if (write_b) ram[addr_b] <= next_ram_b;
    end

endmodule