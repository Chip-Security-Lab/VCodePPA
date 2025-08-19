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
    reg [1:0] cycle_counter_stage1, cycle_counter_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    reg [DATA_WIDTH-1:0] din_stage1, din_stage2;
    reg we_stage1, we_stage2;
    reg valid_stage1, valid_stage2;
    wire [1:0] next_cycle_stage1, next_cycle_stage2;
    wire [1:0] cycle_diff_stage1, cycle_diff_stage2;
    wire borrow_stage1, borrow_stage2;

    // Stage 1 logic
    assign cycle_diff_stage1 = CYCLE_COUNT - cycle_counter_stage1;
    assign borrow_stage1 = (cycle_counter_stage1 > CYCLE_COUNT);
    assign next_cycle_stage1 = borrow_stage1 ? 2'b00 : cycle_counter_stage1 + 1;

    // Stage 2 logic
    assign cycle_diff_stage2 = CYCLE_COUNT - cycle_counter_stage2;
    assign borrow_stage2 = (cycle_counter_stage2 > CYCLE_COUNT);
    assign next_cycle_stage2 = borrow_stage2 ? 2'b00 : cycle_counter_stage2 + 1;

    // Pipeline stage 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter_stage1 <= 0;
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            cycle_counter_stage1 <= next_cycle_stage1;
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            valid_stage1 <= 1;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter_stage2 <= 0;
            addr_stage2 <= 0;
            din_stage2 <= 0;
            we_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            cycle_counter_stage2 <= cycle_counter_stage1;
            addr_stage2 <= addr_stage1;
            din_stage2 <= din_stage1;
            we_stage2 <= we_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Memory and output logic
    always @(posedge clk) begin
        if (we_stage2) begin
            ram[addr_stage2] <= din_stage2;
        end
        if (valid_stage2 && cycle_counter_stage2 == CYCLE_COUNT) begin
            dout <= ram[addr_stage2];
        end
    end

endmodule