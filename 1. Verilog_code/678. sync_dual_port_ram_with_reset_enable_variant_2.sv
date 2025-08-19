//SystemVerilog
module sync_dual_port_ram_with_reset_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg en_stage1;
    
    // Stage 2 registers
    reg [DATA_WIDTH-1:0] read_data_a_stage2, read_data_b_stage2;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg en_stage2;
    
    // Stage 3 registers
    reg [DATA_WIDTH-1:0] dout_a_stage3, dout_b_stage3;
    reg en_stage3;

    // Stage 1: Input Latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_stage1, addr_b_stage1} <= 0;
            {we_a_stage1, we_b_stage1} <= 0;
            {din_a_stage1, din_b_stage1} <= 0;
            en_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            en_stage1 <= en;
        end
    end

    // Stage 2: RAM Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {read_data_a_stage2, read_data_b_stage2} <= 0;
        end else begin
            read_data_a_stage2 <= ram[addr_a_stage1];
            read_data_b_stage2 <= ram[addr_b_stage1];
        end
    end

    // Stage 2: Control Signals Pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_stage2, addr_b_stage2} <= 0;
            {we_a_stage2, we_b_stage2} <= 0;
            {din_a_stage2, din_b_stage2} <= 0;
            en_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            en_stage2 <= en_stage1;
        end
    end

    // Stage 2: RAM Write
    always @(posedge clk) begin
        if (en_stage1) begin
            if (we_a_stage1) ram[addr_a_stage1] <= din_a_stage1;
            if (we_b_stage1) ram[addr_b_stage1] <= din_b_stage1;
        end
    end

    // Stage 3: Forwarding Logic for Port A
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a_stage3 <= 0;
        end else if (en_stage2) begin
            if (we_a_stage2 && addr_a_stage2 == addr_a_stage1)
                dout_a_stage3 <= din_a_stage2;
            else if (we_b_stage2 && addr_b_stage2 == addr_a_stage1)
                dout_a_stage3 <= din_b_stage2;
            else
                dout_a_stage3 <= read_data_a_stage2;
        end
    end

    // Stage 3: Forwarding Logic for Port B
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_b_stage3 <= 0;
        end else if (en_stage2) begin
            if (we_a_stage2 && addr_a_stage2 == addr_b_stage1)
                dout_b_stage3 <= din_a_stage2;
            else if (we_b_stage2 && addr_b_stage2 == addr_b_stage1)
                dout_b_stage3 <= din_b_stage2;
            else
                dout_b_stage3 <= read_data_b_stage2;
        end
    end

    // Stage 3: Enable Pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            en_stage3 <= 0;
        end else begin
            en_stage3 <= en_stage2;
        end
    end

    // Output Stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {dout_a, dout_b} <= 0;
        end else begin
            dout_a <= dout_a_stage3;
            dout_b <= dout_b_stage3;
        end
    end

endmodule