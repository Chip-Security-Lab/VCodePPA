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

    // Pipeline stage 1 signals
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg read_first_stage1;
    
    // Pipeline stage 2 signals
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg read_first_stage2;
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;

    // Conditional sum signals
    reg [DATA_WIDTH-1:0] sum_a, sum_b;
    reg [DATA_WIDTH-1:0] carry_a, carry_b;
    reg [DATA_WIDTH-1:0] temp_a, temp_b;

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // Stage 1: Address and control signal registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_stage1, addr_b_stage1, din_a_stage1, din_b_stage1} <= 0;
            {we_a_stage1, we_b_stage1, read_first_stage1} <= 0;
        end else begin
            {addr_a_stage1, addr_b_stage1} <= {addr_a, addr_b};
            {din_a_stage1, din_b_stage1} <= {din_a, din_b};
            {we_a_stage1, we_b_stage1, read_first_stage1} <= {we_a, we_b, read_first};
        end
    end

    // Stage 2: RAM access and write operation with conditional sum
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_stage2, addr_b_stage2, din_a_stage2, din_b_stage2} <= 0;
            {we_a_stage2, we_b_stage2, read_first_stage2} <= 0;
            {ram_data_a_stage2, ram_data_b_stage2} <= 0;
            {sum_a, sum_b, carry_a, carry_b, temp_a, temp_b} <= 0;
        end else begin
            {addr_a_stage2, addr_b_stage2} <= {addr_a_stage1, addr_b_stage1};
            {din_a_stage2, din_b_stage2} <= {din_a_stage1, din_b_stage1};
            {we_a_stage2, we_b_stage2, read_first_stage2} <= {we_a_stage1, we_b_stage1, read_first_stage1};
            
            // RAM read operations with conditional sum
            temp_a = ram[addr_a_stage1];
            temp_b = ram[addr_b_stage1];
            
            // Conditional sum for port A
            sum_a = temp_a ^ din_a_stage1;
            carry_a = temp_a & din_a_stage1;
            ram_data_a_stage2 = sum_a + carry_a;
            
            // Conditional sum for port B
            sum_b = temp_b ^ din_b_stage1;
            carry_b = temp_b & din_b_stage1;
            ram_data_b_stage2 = sum_b + carry_b;
            
            // RAM write operations
            if (we_a_stage1) ram[addr_a_stage1] <= din_a_stage1;
            if (we_b_stage1) ram[addr_b_stage1] <= din_b_stage1;
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {dout_a, dout_b} <= 0;
        end else begin
            {dout_a, dout_b} <= {ram_data_a_stage2, ram_data_b_stage2};
        end
    end
endmodule