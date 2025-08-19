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
    reg [$clog2(CYCLE_COUNT):0] cycle_counter;
    reg [DATA_WIDTH-1:0] dout_next;
    wire cycle_complete;

    assign cycle_complete = (cycle_counter == CYCLE_COUNT-1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
            cycle_counter <= {($clog2(CYCLE_COUNT)+1){1'b0}};
            dout_next <= {DATA_WIDTH{1'b0}};
        end else begin
            case ({we, cycle_complete})
                2'b10: begin
                    ram[addr] <= din;
                    cycle_counter <= {($clog2(CYCLE_COUNT)+1){1'b0}};
                    dout_next <= {DATA_WIDTH{1'b0}};
                end
                2'b01: begin
                    dout <= ram[addr];
                    cycle_counter <= {($clog2(CYCLE_COUNT)+1){1'b0}};
                end
                default: begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            endcase
        end
    end
endmodule