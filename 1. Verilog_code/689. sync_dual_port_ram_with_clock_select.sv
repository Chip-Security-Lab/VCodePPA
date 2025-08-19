module sync_dual_port_ram_with_clock_select #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // Port A
    always @(posedge clk_a) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_a) begin
                ram[addr_a] <= din_a;
            end
            dout_a <= ram[addr_a];
        end
    end

    // Port B
    always @(posedge clk_b) begin
        if (rst) begin
            dout_b <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_b) begin
                ram[addr_b] <= din_b;
            end
            dout_b <= ram[addr_b];
        end
    end
endmodule