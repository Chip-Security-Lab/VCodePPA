//SystemVerilog
module sync_dual_port_ram_with_clock_sync_pipeline #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // Pipeline registers
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;

    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;

    reg [DATA_WIDTH-1:0] dout_a_stage3, dout_b_stage3;
    reg [DATA_WIDTH-1:0] dout_a_stage4, dout_b_stage4;

    // Stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
        end else begin
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
        end
    end

    // Stage 2: Address and write enable propagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
        end else begin
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
        end
    end

    // Stage 3: Write operations and read address preparation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a_stage3 <= 0;
            dout_b_stage3 <= 0;
        end else begin
            if (we_a_stage2) ram[addr_a_stage2] <= din_a_stage2;
            if (we_b_stage2) ram[addr_b_stage2] <= din_b_stage2;
            dout_a_stage3 <= ram[addr_a_stage2];
            dout_b_stage3 <= ram[addr_b_stage2];
        end
    end

    // Stage 4: Read data propagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a_stage4 <= 0;
            dout_b_stage4 <= 0;
        end else begin
            dout_a_stage4 <= dout_a_stage3;
            dout_b_stage4 <= dout_b_stage3;
        end
    end

    // Final outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= dout_a_stage4;
            dout_b <= dout_b_stage4;
        end
    end

endmodule